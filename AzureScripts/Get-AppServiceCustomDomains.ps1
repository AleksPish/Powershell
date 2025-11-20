# Get-AppServiceCustomDomains.ps1
# Script to retrieve all custom domains configured on Azure App Services in a subscription

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

# Check if Azure PowerShell module is installed
if (!(Get-Module -ListAvailable -Name Az.Websites)) {
    Write-Error "Azure PowerShell module (Az.Websites) is not installed. Please install it using: Install-Module -Name Az"
    exit 1
}

try {
    # Connect to Azure if not already connected
    $context = Get-AzContext
    if (!$context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }

    # Set subscription if provided
    if ($SubscriptionId) {
        Write-Host "Setting subscription context to: $SubscriptionId" -ForegroundColor Green
        Set-AzContext -SubscriptionId $SubscriptionId
    }

    # Get current subscription info
    $currentContext = Get-AzContext
    Write-Host "Working with subscription: $($currentContext.Subscription.Name) ($($currentContext.Subscription.Id))" -ForegroundColor Green

    # Get all App Services (optionally filtered by resource group)
    Write-Host "Retrieving App Services..." -ForegroundColor Yellow
    
    if ($ResourceGroupName) {
        $webApps = Get-AzWebApp -ResourceGroupName $ResourceGroupName
        Write-Host "Found $($webApps.Count) App Services in resource group: $ResourceGroupName" -ForegroundColor Green
    } else {
        $webApps = Get-AzWebApp
        Write-Host "Found $($webApps.Count) App Services in subscription" -ForegroundColor Green
    }

    # Initialize results array
    $results = @()

    foreach ($webApp in $webApps) {
        Write-Host "Processing: $($webApp.Name)" -ForegroundColor Cyan
        
        # Get detailed configuration including custom domains
        $webAppDetails = Get-AzWebApp -ResourceGroupName $webApp.ResourceGroup -Name $webApp.Name
        
        # Filter out default Azure domains and get only custom domains
        $customDomains = $webAppDetails.HostNames | Where-Object { 
            $_ -notlike "*.azurewebsites.net" -and 
            $_ -notlike "*.scm.azurewebsites.net" 
        }
        
        if ($customDomains) {
            foreach ($domain in $customDomains) {
                # Get SSL binding info for the domain
                $sslBinding = $webAppDetails.HostNameSslStates | Where-Object { $_.Name -eq $domain }
                
                $result = [PSCustomObject]@{
                    SubscriptionId = $currentContext.Subscription.Id
                    SubscriptionName = $currentContext.Subscription.Name
                    ResourceGroup = $webApp.ResourceGroup
                    AppServiceName = $webApp.Name
                    CustomDomain = $domain
                    SSLState = $sslBinding.SslState
                    CertificateThumbprint = $sslBinding.Thumbprint
                    Location = $webApp.Location
                    AppServicePlan = $webApp.ServerFarmId.Split('/')[-1]
                    State = $webApp.State
                    Kind = $webApp.Kind
                }
                $results += $result
            }
        }
    }

    # Display results
    if ($results.Count -gt 0) {
        Write-Host "`nFound $($results.Count) custom domains:" -ForegroundColor Green
        $results | Format-Table -AutoSize
        
        # Export to CSV if output path is provided
        if ($OutputPath) {
            $results | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host "Results exported to: $OutputPath" -ForegroundColor Green
        }
    } else {
        Write-Host "No custom domains found in the specified scope." -ForegroundColor Yellow
    }

    # Summary by App Service
    Write-Host "`nSummary by App Service:" -ForegroundColor Magenta
    $summary = $results | Group-Object AppServiceName | Select-Object Name, Count
    $summary | Format-Table -AutoSize

} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}