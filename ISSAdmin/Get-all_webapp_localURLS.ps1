Import-Module WebAdministration


# Get all sites and their bindings
$sites = Get-ChildItem IIS:\Sites

# Get the hostname of the server
$hostname = $env:COMPUTERNAME

# Initialize an array to store URLs that contain the hostname
$filteredUrls = @()

# Get all sites and their bindings
foreach ($site in $sites) {
    $apps = Get-WebApplication -Site $site.Name
    foreach ($app in $apps) {
        $bindings = $site.Bindings.Collection
        foreach ($binding in $bindings) {
            # Construct the URL from protocol, binding information, and application path
            $url = "$($binding.Protocol)://$($binding.BindingInformation)$($app.Path)"
            # Clean up the URL (remove port and wildcard if present, e.g., "*:80:")
            $url = $url -replace '\*:\d+:', ''  # Replace "*:80:" or similar with nothing
            if ($url -like "*$hostname*") {
                $filteredUrls += $url
            }
        }
    }
}

# Output the filtered URLs
$filteredUrls | ForEach-Object { Write-Output $_ }

foreach ($url in $filteredUrls) {
    Start-Process "iexplore.exe" $url
    Start-Sleep -Seconds 10
}
