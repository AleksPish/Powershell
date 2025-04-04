#Requires -Modules Az.Accounts, Az.Network

<#
.SYNOPSIS
    Lists all virtual networks across all subscriptions in an Azure tenant.

.DESCRIPTION
    This script retrieves all subscriptions in the Azure tenant, loops through each one,
    sets the context to that subscription, and retrieves all virtual networks.
    For each vnet found, it displays the subscription name, vnet name, resource group, and location.

.NOTES
    File Name      : GetAllAzureVnets.ps1
    Prerequisite   : Az PowerShell modules (Az.Accounts, Az.Network)
    Version        : 1.0
#>

# Check if the user is connected to Azure
try {
    $context = Get-AzContext -ErrorAction Stop
    if (-not $context) {
        Write-Host "You are not connected to Azure. Connecting now..." -ForegroundColor Yellow
        Connect-AzAccount
    } else {
        Write-Host "Currently connected to Azure with account: $($context.Account)" -ForegroundColor Green
    }
} catch {
    Write-Host "You are not connected to Azure. Connecting now..." -ForegroundColor Yellow
    Connect-AzAccount
}

# Create an array to store the results
$allVnets = @()

# Get all subscriptions
Write-Host "Getting all subscriptions..." -ForegroundColor Cyan
$subscriptions = Get-AzSubscription
$totalSubscriptions = $subscriptions.Count
Write-Host "Found $totalSubscriptions subscriptions" -ForegroundColor Cyan

# Loop through each subscription
$currentSubscription = 0
foreach ($subscription in $subscriptions) {
    $currentSubscription++
    $subscriptionName = $subscription.Name
    $subscriptionId = $subscription.Id
    
    Write-Host "Processing subscription $currentSubscription of $totalSubscriptions : $subscriptionName ($subscriptionId)" -ForegroundColor Yellow
    
    # Set the context to the current subscription
    try {
        Set-AzContext -SubscriptionId $subscriptionId -ErrorAction Stop | Out-Null
        
        # Get all virtual networks in the current subscription
        $vnets = Get-AzVirtualNetwork
        
        if ($vnets) {
            $vnetsCount = $vnets.Count
            Write-Host "  Found $vnetsCount virtual networks in subscription $subscriptionName" -ForegroundColor Green
            
            # Add each vnet to the results array
            foreach ($vnet in $vnets) {
                $vnetObject = [PSCustomObject]@{
                    SubscriptionName = $subscriptionName
                    SubscriptionId = $subscriptionId
                    VNetName = $vnet.Name
                    ResourceGroup = $vnet.ResourceGroupName
                    Location = $vnet.Location
                    AddressSpace = ($vnet.AddressSpace.AddressPrefixes -join ", ")
                }
                $allVnets += $vnetObject
            }
        } else {
            Write-Host "  No virtual networks found in subscription $subscriptionName" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  Error accessing subscription $subscriptionName : $_" -ForegroundColor Red
    }
}

# Display the results
if ($allVnets.Count -gt 0) {
    Write-Host "`nFound a total of $($allVnets.Count) virtual networks across $totalSubscriptions subscriptions" -ForegroundColor Green
    $allVnets | Format-Table -Property SubscriptionName, VNetName, ResourceGroup, Location, AddressSpace -AutoSize
    
    # Optionally export to CSV
    $exportCsv = Read-Host "Would you like to export the results to CSV? (Y/N)"
    if ($exportCsv -eq "Y" -or $exportCsv -eq "y") {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $csvPath = ".\AzureVirtualNetworks-$timestamp.csv"
        $allVnets | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Host "Results exported to $csvPath" -ForegroundColor Green
    }
} else {
    Write-Host "`nNo virtual networks found in any subscription" -ForegroundColor Yellow
}

