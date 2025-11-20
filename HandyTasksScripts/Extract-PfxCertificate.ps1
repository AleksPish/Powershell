param(
    [Parameter(Mandatory=$true)]
    [string]$PfxPath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDirectory = ".",
    
    [Parameter(Mandatory=$false)]
    [string]$Password
)

# Validate input file exists
if (-not (Test-Path $PfxPath)) {
    Write-Error "PFX file not found: $PfxPath"
    exit 1
}

# Get the base name for output files
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($PfxPath)
$certFile = Join-Path $OutputDirectory "$baseName.crt"
$keyFile = Join-Path $OutputDirectory "$baseName.key"
$combinedFile = Join-Path $OutputDirectory "$baseName-combined.pem"

Write-Host "Processing PFX file: $PfxPath" -ForegroundColor Green
Write-Host "Output directory: $OutputDirectory" -ForegroundColor Green

try {
    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    }

    # Prepare password parameter
    $passwordParam = ""
    if ($Password) {
        $passwordParam = "-passin pass:$Password"
    }

    Write-Host "`nExtracting public certificate..." -ForegroundColor Yellow
    
    # Extract public certificate (no private key)
    $extractCertCmd = "openssl pkcs12 -in `"$PfxPath`" -nokeys -out `"$certFile`" $passwordParam"
    Write-Host "Running: $extractCertCmd"
    Invoke-Expression $extractCertCmd
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to extract certificate"
    }

    Write-Host "`nExtracting private key..." -ForegroundColor Yellow
    
    # Extract private key (encrypted by default)
    $extractKeyCmd = "openssl pkcs12 -in `"$PfxPath`" -nocerts -out `"$keyFile`" $passwordParam"
    Write-Host "Running: $extractKeyCmd"
    Invoke-Expression $extractKeyCmd
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to extract private key"
    }

    Write-Host "`nExtracting combined certificate and key..." -ForegroundColor Yellow
    
    # Extract both certificate and private key in one file
    $extractBothCmd = "openssl pkcs12 -in `"$PfxPath`" -out `"$combinedFile`" $passwordParam"
    Write-Host "Running: $extractBothCmd"
    Invoke-Expression $extractBothCmd
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to extract combined file"
    }

    Write-Host "`nCalculating certificate thumbprints..." -ForegroundColor Yellow
    
    # Get SHA1 thumbprint
    Write-Host "`nSHA1 Thumbprint:" -ForegroundColor Cyan
    $sha1Cmd = "openssl x509 -in `"$certFile`" -fingerprint -noout -sha1"
    $sha1Result = Invoke-Expression $sha1Cmd
    if ($LASTEXITCODE -eq 0) {
        $sha1Thumbprint = ($sha1Result -split "=")[1]
        Write-Host $sha1Thumbprint -ForegroundColor White
    } else {
        Write-Error "Failed to get SHA1 thumbprint"
    }
    
    # Get SHA256 thumbprint
    Write-Host "`nSHA256 Thumbprint:" -ForegroundColor Cyan
    $sha256Cmd = "openssl x509 -in `"$certFile`" -fingerprint -noout -sha256"
    $sha256Result = Invoke-Expression $sha256Cmd
    if ($LASTEXITCODE -eq 0) {
        $sha256Thumbprint = ($sha256Result -split "=")[1]
        Write-Host $sha256Thumbprint -ForegroundColor White
    } else {
        Write-Error "Failed to get SHA256 thumbprint"
    }

    # Display certificate information
    Write-Host "`nCertificate Information:" -ForegroundColor Yellow
    $certInfoCmd = "openssl x509 -in `"$certFile`" -text -noout"
    Invoke-Expression $certInfoCmd

    Write-Host "`n=== EXTRACTION SUMMARY ===" -ForegroundColor Green
    Write-Host "Files created:" -ForegroundColor Yellow
    Write-Host "  - Certificate: $certFile" -ForegroundColor White
    Write-Host "  - Private Key: $keyFile" -ForegroundColor White
    Write-Host "  - Combined: $combinedFile" -ForegroundColor White
    Write-Host "`nThumbprints:" -ForegroundColor Yellow
    if ($sha1Thumbprint) { Write-Host "  - SHA1:   $sha1Thumbprint" -ForegroundColor White }
    if ($sha256Thumbprint) { Write-Host "  - SHA256: $sha256Thumbprint" -ForegroundColor White }

} catch {
    Write-Error "Error processing PFX file: $_"
    exit 1
}

Write-Host "`nExtraction completed successfully!" -ForegroundColor Green
