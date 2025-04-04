#Find all assigned hostnames on app gateway listeners

# List all Application Gateways in the subscription
$applicationGateways = Get-AzApplicationGateway

foreach ($appGateway in $applicationGateways) {
    Write-Host "Application Gateway: $($appGateway.Name)"
    Write-Host "Listeners and Hostnames:"
    foreach ($listener in $appGateway.HttpListeners) {
        Write-Host "  Listener: $($listener.Name)"
        if ($listener.HostNames) {
            Write-Host "    Hostname: $($listener.HostNames)"
        } else {
            Write-Host "    No hostname configured for this listener"
        }
    }
}
