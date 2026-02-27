# === Configuration ===
$thumbprint          = "A1B2C3D4E5F67890123456789ABCDEF012345678"   # cert thumbprint
$connectionBroker    = "rdcb.yourdomain.com"                        # FQDN or hostname of your RD Connection Broker
$force               = $true                                        # Skip confirmations

# List of all relevant RDS roles that use certificates
$roles = @(
    "RDGateway",     # RD Gateway SSL
    "RDWebAccess",   # RD Web / HTML5
    "RDRedirector",  # SSO / redirection
    "RDPublishing"   # Publishing / feed
)

# Apply to each role
foreach ($role in $roles) {
    Write-Host "Applying certificate to role: $role ..." -ForegroundColor Cyan
    Set-RDCertificate -Role $role `
                      -Thumbprint $thumbprint `
                      -ConnectionBroker $connectionBroker `
                      -Force:$force `
                      -Verbose    # optional: see detailed output
}