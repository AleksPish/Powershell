# Get-AppServiceDefaultDomains.ps1
# Script to retrieve all default Azure domain names (*.azurewebsites.net) for Azure App Services in a subscription

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
        
        # Get detailed configuration including all domains
        $webAppDetails = Get-AzWebApp -ResourceGroupName $webApp.ResourceGroup -Name $webApp.Name
        
        # Get default Azure domains (*.azurewebsites.net but exclude SCM domains)
        $defaultDomains = $webAppDetails.HostNames | Where-Object { 
            $_ -like "*.azurewebsites.net" -and 
            $_ -notlike "*.scm.azurewebsites.net" 
        }
        
        foreach ($domain in $defaultDomains) {
            # Get SSL binding info for the domain
            $sslBinding = $webAppDetails.HostNameSslStates | Where-Object { $_.Name -eq $domain }
            
            $result = [PSCustomObject]@{
                SubscriptionId = $currentContext.Subscription.Id
                SubscriptionName = $currentContext.Subscription.Name
                ResourceGroup = $webApp.ResourceGroup
                AppServiceName = $webApp.Name
                DefaultDomain = $domain
                FullURL = "https://$domain"
                SSLState = $sslBinding.SslState
                Location = $webApp.Location
                AppServicePlan = $webApp.ServerFarmId.Split('/')[-1]
                State = $webApp.State
                Kind = $webApp.Kind
                RuntimeStack = if ($webAppDetails.SiteConfig.LinuxFxVersion) { $webAppDetails.SiteConfig.LinuxFxVersion } else { $webAppDetails.SiteConfig.WindowsFxVersion }
                HttpsOnly = $webAppDetails.HttpsOnly
            }
            $results += $result
        }
    }

    # Display results
    if ($results.Count -gt 0) {
        Write-Host "`nFound $($results.Count) default Azure domains:" -ForegroundColor Green
        
        # Show summary view first
        Write-Host "`nSummary View:" -ForegroundColor Yellow
        $results | Format-Table AppServiceName, DefaultDomain, State, Location -AutoSize
        
        # Show detailed view
        Write-Host "`nDetailed Information:" -ForegroundColor Magenta
        $results | Format-Table -AutoSize
        
        # Export to CSV if output path is provided
        if ($OutputPath) {
            $results | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host "Results exported to: $OutputPath" -ForegroundColor Green
        }
    } else {
        Write-Host "No App Services with default domains found in the specified scope." -ForegroundColor Yellow
    }

    # Summary statistics
    Write-Host "`nStatistics:" -ForegroundColor Magenta
    $totalApps = $results.Count
    $runningApps = ($results | Where-Object { $_.State -eq "Running" }).Count
    $stoppedApps = ($results | Where-Object { $_.State -eq "Stopped" }).Count
    $httpsOnlyApps = ($results | Where-Object { $_.HttpsOnly -eq $true }).Count
    
    Write-Host "Total App Services: $totalApps" -ForegroundColor Cyan
    Write-Host "Running Apps: $runningApps" -ForegroundColor Green
    Write-Host "Stopped Apps: $stoppedApps" -ForegroundColor Red
    Write-Host "HTTPS Only Apps: $httpsOnlyApps" -ForegroundColor Yellow
    
    # Group by location
    Write-Host "`nDistribution by Location:" -ForegroundColor Magenta
    $locationSummary = $results | Group-Object Location | Select-Object Name, Count | Sort-Object Count -Descending
    $locationSummary | Format-Table -AutoSize
    
    # Group by App Service Plan
    Write-Host "`nDistribution by App Service Plan:" -ForegroundColor Magenta
    $planSummary = $results | Group-Object AppServicePlan | Select-Object Name, Count | Sort-Object Count -Descending
    $planSummary | Format-Table -AutoSize

} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}