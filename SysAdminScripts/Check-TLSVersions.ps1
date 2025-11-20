# Check TLS versions with Windows Server 2022 defaults

Write-Host "Checking TLS Protocol Versions (Windows Server 2022)..." -ForegroundColor Cyan

$protocols = @(
    @{Name='SSL 2.0'; DefaultEnabled=$false},
    @{Name='SSL 3.0'; DefaultEnabled=$false},
    @{Name='TLS 1.0'; DefaultEnabled=$false},
    @{Name='TLS 1.1'; DefaultEnabled=$false},
    @{Name='TLS 1.2'; DefaultEnabled=$true},
    @{Name='TLS 1.3'; DefaultEnabled=$true}
)

foreach ($protocol in $protocols) {
    $name = $protocol.Name
    $clientPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$name\Client"
    $serverPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$name\Server"
    
    Write-Host "`n$name" -ForegroundColor Yellow
    
    # Check Client
    if (Test-Path $clientPath) {
        $clientEnabled = Get-ItemProperty -Path $clientPath -Name "Enabled" -ErrorAction SilentlyContinue
        $clientDisabled = Get-ItemProperty -Path $clientPath -Name "DisabledByDefault" -ErrorAction SilentlyContinue
        
        $status = if ($clientEnabled.Enabled -eq 1 -and $clientDisabled.DisabledByDefault -ne 1) { "Enabled" } else { "Disabled" }
        Write-Host "  Client: $status (Configured)" -ForegroundColor $(if ($status -eq "Enabled") { "Green" } else { "Red" })
    } else {
        $defaultStatus = if ($protocol.DefaultEnabled) { "Enabled" } else { "Disabled" }
        Write-Host "  Client: $defaultStatus (Default)" -ForegroundColor $(if ($protocol.DefaultEnabled) { "Green" } else { "Gray" })
    }
    
    # Check Server
    if (Test-Path $serverPath) {
        $serverEnabled = Get-ItemProperty -Path $serverPath -Name "Enabled" -ErrorAction SilentlyContinue
        $serverDisabled = Get-ItemProperty -Path $serverPath -Name "DisabledByDefault" -ErrorAction SilentlyContinue
        
        $status = if ($serverEnabled.Enabled -eq 1 -and $serverDisabled.DisabledByDefault -ne 1) { "Enabled" } else { "Disabled" }
        Write-Host "  Server: $status (Configured)" -ForegroundColor $(if ($status -eq "Enabled") { "Green" } else { "Red" })
    } else {
        $defaultStatus = if ($protocol.DefaultEnabled) { "Enabled" } else { "Disabled" }
        Write-Host "  Server: $defaultStatus (Default)" -ForegroundColor $(if ($protocol.DefaultEnabled) { "Green" } else { "Gray" })
    }
}