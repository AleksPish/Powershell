#Set-AzContext -SubscriptionId '<subscription ID>'
# Configure the certificate thumbprint, resource group, and web app name.
$certificateThumbprint = "<certificate thumbprint>"
$resourceGroupName     = "<resource group>"
$webAppName            = "<Web App Name>"
$cert                  = "<certificate name to update eg contorso.com>"
 
# Get the web app, based on its resource group and name.
$webApp = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName
 
# Update the TLS/SSL binding for every custom hostname.
foreach ($hostName in $webApp.HostNames)
{
    if ($hostName.EndsWith("azurewebsites.net"))
    {
        # Skip the default Azure hostname.
        continue
    }
    
    if ($hostName.EndsWith("$cert"))
    {
    # Add/update the binding to the certificate with the specified thumbprint.
        New-AzWebAppSSLBinding `
            -ResourceGroupName $resourceGroupName `
            -WebAppName $webAppName `
            -Thumbprint $certificateThumbprint `
            -Name $hostName
        
        Write-Host "Updated binding for: $hostName"
    }
        # Skip all other HostNames
        continue
}