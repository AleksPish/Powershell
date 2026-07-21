#Requires -Modules Az.Accounts, Az.Resources, Az.Websites, Az.Network

<#
.SYNOPSIS
    Gets all resources integrated with or connected to a specific Azure subnet.

.DESCRIPTION
    Searches a subscription for every resource that is attached to the specified subnet,
    including:
      - App Services and Function Apps (VNet Integration)
      - Virtual Machines and Network Interfaces
      - Private Endpoints
      - Subnet Delegations and Service Endpoints (reported as subnet-level metadata)

    Results are written to the console and optionally exported to a CSV file.

.PARAMETER SubscriptionId
    The Azure subscription ID to search. If omitted the current Az context is used.

.PARAMETER VNetResourceGroup
    Resource group that contains the virtual network.

.PARAMETER VNetName
    Name of the virtual network that contains the target subnet.

.PARAMETER SubnetName
    Name of the subnet to search for connected resources.

.PARAMETER OutputPath
    Full path for the CSV export file.
    Defaults to Get-SubnetResources-<VNetName>-<SubnetName>-<timestamp>.csv in the script directory.

.EXAMPLE
    .\Get-SubnetConnectedResources.ps1 `
        -SubscriptionId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
        -VNetResourceGroup "rg-network" `
        -VNetName "vnet-prod-uks" `
        -SubnetName "snet-appservices"

.EXAMPLE
    .\Get-SubnetConnectedResources.ps1 `
        -VNetResourceGroup "rg-network" `
        -VNetName "vnet-dev-uks" `
        -SubnetName "snet-functions" `
        -OutputPath "C:\Reports\subnet-resources.csv"
#>

[CmdletBinding()]
param (
    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [string]$VNetResourceGroup,

    [Parameter(Mandatory)]
    [string]$VNetName,

    [Parameter(Mandatory)]
    [string]$SubnetName,

    [string]$OutputPath
)

#region ── Helpers ──────────────────────────────────────────────────────────────

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("─" * 70) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("─" * 70) -ForegroundColor Cyan
}

function New-ResultRow {
    param(
        [string]$ResourceType,
        [string]$ResourceName,
        [string]$ResourceGroup,
        [string]$ConnectionType,
        [string]$Details = ""
    )
    [PSCustomObject]@{
        ResourceType   = $ResourceType
        ResourceName   = $ResourceName
        ResourceGroup  = $ResourceGroup
        ConnectionType = $ConnectionType
        Details        = $Details
        SubnetName     = $SubnetName
        VNetName       = $VNetName
    }
}

#endregion

#region ── Azure context ────────────────────────────────────────────────────────

# Ensure the user is signed in
$context = Get-AzContext -ErrorAction SilentlyContinue
if (-not $context) {
    Write-Host "No Azure context found. Signing in..." -ForegroundColor Yellow
    Connect-AzAccount
    $context = Get-AzContext
}

if ($SubscriptionId) {
    Write-Host "Setting subscription context to: $SubscriptionId" -ForegroundColor Yellow
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    $context = Get-AzContext
}

Write-Host "Using subscription: $($context.Subscription.Name) [$($context.Subscription.Id)]" -ForegroundColor Green

#endregion

#region ── Resolve subnet ───────────────────────────────────────────────────────

Write-Host ""
Write-Host "Resolving VNet '$VNetName' in resource group '$VNetResourceGroup'..." -ForegroundColor Yellow

$vnet = Get-AzVirtualNetwork -ResourceGroupName $VNetResourceGroup -Name $VNetName -ErrorAction Stop

$subnet = $vnet.Subnets | Where-Object { $_.Name -eq $SubnetName }
if (-not $subnet) {
    Write-Error "Subnet '$SubnetName' not found in VNet '$VNetName'. Available subnets: $(($vnet.Subnets.Name) -join ', ')"
    exit 1
}

$subnetId    = $subnet.Id
$subnetCidr  = ($subnet.AddressPrefix | Where-Object { $_ }) -join ", "

Write-Host "Found subnet: $subnetId" -ForegroundColor Green
Write-Host "Address prefix(es): $subnetCidr" -ForegroundColor Green

# Default output path now that we know VNet/Subnet names
if (-not $OutputPath) {
    $timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "Get-SubnetResources-${VNetName}-${SubnetName}-${timestamp}.csv"
}

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

#endregion

#region ── 1. Subnet metadata (delegations + service endpoints) ─────────────────

Write-Section "Subnet metadata"

$delegations = $subnet.Delegations
if ($delegations) {
    foreach ($d in $delegations) {
        Write-Host "  [Delegation] $($d.ServiceName)" -ForegroundColor Magenta
        $results.Add((New-ResultRow `
            -ResourceType   "Subnet Delegation" `
            -ResourceName   $d.Name `
            -ResourceGroup  $VNetResourceGroup `
            -ConnectionType "Delegation" `
            -Details        $d.ServiceName))
    }
} else {
    Write-Host "  No delegations configured." -ForegroundColor DarkGray
}

$serviceEndpoints = $subnet.ServiceEndpoints
if ($serviceEndpoints) {
    foreach ($se in $serviceEndpoints) {
        Write-Host "  [Service Endpoint] $($se.Service)" -ForegroundColor Magenta
        $results.Add((New-ResultRow `
            -ResourceType   "Service Endpoint" `
            -ResourceName   $se.Service `
            -ResourceGroup  $VNetResourceGroup `
            -ConnectionType "Service Endpoint" `
            -Details        ("Locations: " + ($se.Locations -join ", "))))
    }
} else {
    Write-Host "  No service endpoints configured." -ForegroundColor DarkGray
}

#endregion

#region ── 2. App Services and Function Apps (VNet Integration) ─────────────────

Write-Section "App Services / Function Apps (VNet Integration)"

$webApps = Get-AzWebApp -ErrorAction SilentlyContinue
$matchedApps = $webApps | Where-Object {
    $_.VirtualNetworkSubnetId -and
    $_.VirtualNetworkSubnetId -eq $subnetId
}

if ($matchedApps) {
    foreach ($app in $matchedApps) {
        $kind = if ($app.Kind -match "functionapp") { "Function App" } else { "App Service" }
        Write-Host "  [$kind] $($app.Name)  (RG: $($app.ResourceGroup))" -ForegroundColor Green
        $results.Add((New-ResultRow `
            -ResourceType   $kind `
            -ResourceName   $app.Name `
            -ResourceGroup  $app.ResourceGroup `
            -ConnectionType "VNet Integration" `
            -Details        "Kind: $($app.Kind)  ASP: $($app.ServerFarmId.Split('/')[-1])"))
    }
} else {
    Write-Host "  No App Services or Function Apps found on this subnet." -ForegroundColor DarkGray
}

#endregion

#region ── 3. Network Interfaces (VMs, VMSS, bare NICs) ────────────────────────

Write-Section "Network Interfaces (VMs / VMSS / other NIC-attached resources)"

$nics = Get-AzNetworkInterface -ErrorAction SilentlyContinue
$matchedNics = $nics | Where-Object {
    $_.IpConfigurations | Where-Object { $_.Subnet.Id -eq $subnetId }
}

if ($matchedNics) {
    foreach ($nic in $matchedNics) {

        # Determine what the NIC is attached to
        $attachedTo = "Unattached"
        $attachedType = "Network Interface"

        if ($nic.VirtualMachine) {
            $vmName = $nic.VirtualMachine.Id.Split('/')[-1]
            $attachedTo  = $vmName
            $attachedType = "Virtual Machine"
        } elseif ($nic.PrivateEndpoint) {
            $peName = $nic.PrivateEndpoint.Id.Split('/')[-1]
            $attachedTo  = $peName
            $attachedType = "Private Endpoint (NIC)"
        }

        $privateIPs = ($nic.IpConfigurations |
            Where-Object { $_.Subnet.Id -eq $subnetId } |
            ForEach-Object { $_.PrivateIpAddress }) -join ", "

        Write-Host "  [$attachedType] $($nic.Name)  → $attachedTo  (IPs: $privateIPs)" -ForegroundColor Green
        $results.Add((New-ResultRow `
            -ResourceType   $attachedType `
            -ResourceName   $attachedTo `
            -ResourceGroup  $nic.ResourceGroupName `
            -ConnectionType "NIC attached to subnet" `
            -Details        "NIC: $($nic.Name)  Private IPs: $privateIPs"))
    }
} else {
    Write-Host "  No NICs found attached to this subnet." -ForegroundColor DarkGray
}

#endregion

#region ── 4. Private Endpoints ────────────────────────────────────────────────

Write-Section "Private Endpoints"

$privateEndpoints = Get-AzPrivateEndpoint -ErrorAction SilentlyContinue
$matchedPEs = $privateEndpoints | Where-Object {
    $_.Subnet.Id -eq $subnetId
}

if ($matchedPEs) {
    foreach ($pe in $matchedPEs) {
        $linkedResources = ($pe.PrivateLinkServiceConnections +
                            $pe.ManualPrivateLinkServiceConnections) |
                           ForEach-Object { $_.PrivateLinkServiceId.Split('/')[-1] }
        $linkedStr = $linkedResources -join ", "

        Write-Host "  [Private Endpoint] $($pe.Name)  → $linkedStr  (RG: $($pe.ResourceGroupName))" -ForegroundColor Green
        $results.Add((New-ResultRow `
            -ResourceType   "Private Endpoint" `
            -ResourceName   $pe.Name `
            -ResourceGroup  $pe.ResourceGroupName `
            -ConnectionType "Private Endpoint" `
            -Details        "Linked resource(s): $linkedStr"))
    }
} else {
    Write-Host "  No private endpoints found on this subnet." -ForegroundColor DarkGray
}

#endregion

#region ── Summary ──────────────────────────────────────────────────────────────

Write-Section "Summary"
Write-Host "  Subnet     : $subnetId"
Write-Host "  CIDR       : $subnetCidr"
Write-Host "  Total rows : $($results.Count)"
Write-Host ""

if ($results.Count -gt 0) {
    $results | Format-Table -AutoSize
} else {
    Write-Host "  No connected resources found." -ForegroundColor Yellow
}

#endregion

#region ── CSV export ───────────────────────────────────────────────────────────

if ($results.Count -gt 0) {
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Results exported to: $OutputPath" -ForegroundColor Cyan
} else {
    Write-Host "No results to export." -ForegroundColor Yellow
}

#endregion
