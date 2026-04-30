#Requires -Version 5.1
<#
.SYNOPSIS
    Extracts the full certificate chain and unencrypted private key from a PFX file using OpenSSL.

.DESCRIPTION
    Uses OpenSSL to extract:
      - The private key (unencrypted, PEM format)
      - The full certificate chain (PEM format)
      - A combined PEM file containing both

.PARAMETER PfxPath
    Path to the source PFX file.

.PARAMETER OutputDir
    Directory where the extracted files will be saved. Defaults to the same directory as the PFX file.

.PARAMETER PfxPassword
    Password for the PFX file. If not provided, you will be prompted.

.EXAMPLE
    .\Extract-PfxContents.ps1 -PfxPath "C:\certs\mycert.pfx"

.EXAMPLE
    .\Extract-PfxContents.ps1 -PfxPath "C:\certs\mycert.pfx" -OutputDir "C:\output" -PfxPassword "s3cr3t"
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$PfxPath,

    [Parameter()]
    [string]$OutputDir,

    [Parameter()]
    [string]$PfxPassword
)

# Verify OpenSSL is available
if (-not (Get-Command openssl -ErrorAction SilentlyContinue)) {
    Write-Error "OpenSSL not found. Install it or add it to your PATH (e.g. via Git for Windows, Chocolatey, or the Win32 OpenSSL installer)."
    exit 1
}

# Resolve paths
$PfxPath   = Resolve-Path $PfxPath | Select-Object -ExpandProperty Path
$baseName  = [System.IO.Path]::GetFileNameWithoutExtension($PfxPath)

if (-not $OutputDir) {
    $OutputDir = Split-Path $PfxPath -Parent
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Prompt for password if not supplied
if (-not $PfxPassword) {
    $securePass  = Read-Host "Enter PFX password (leave blank if none)" -AsSecureString
    $BSTR        = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
    $PfxPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}

$keyFile      = Join-Path $OutputDir "$baseName-key.pem"
$chainFile    = Join-Path $OutputDir "$baseName-chain.pem"
$combinedFile = Join-Path $OutputDir "$baseName-combined.pem"

Write-Host "`nExtracting from: $PfxPath" -ForegroundColor Cyan
Write-Host "Output directory: $OutputDir`n" -ForegroundColor Cyan

# Extract unencrypted private key
Write-Host "Extracting private key..." -ForegroundColor Yellow
$opensslArgs = @("pkcs12", "-in", $PfxPath, "-nocerts", "-nodes", "-out", $keyFile, "-passin", "pass:$PfxPassword")
& openssl @opensslArgs 2>&1 | ForEach-Object { Write-Verbose $_ }
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to extract private key. Check your password and PFX file."
    exit 1
}
Write-Host "  -> $keyFile" -ForegroundColor Green

# Extract full certificate chain (all certs including CA chain)
Write-Host "Extracting certificate chain..." -ForegroundColor Yellow
$opensslArgs = @("pkcs12", "-in", $PfxPath, "-nokeys", "-chain", "-out", $chainFile, "-passin", "pass:$PfxPassword")
& openssl @opensslArgs 2>&1 | ForEach-Object { Write-Verbose $_ }
if ($LASTEXITCODE -ne 0) {
    # Fall back without -chain flag (some OpenSSL builds / PFX formats differ)
    Write-Warning "-chain flag failed, retrying without it..."
    $opensslArgs = @("pkcs12", "-in", $PfxPath, "-nokeys", "-out", $chainFile, "-passin", "pass:$PfxPassword")
    & openssl @opensslArgs 2>&1 | ForEach-Object { Write-Verbose $_ }
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to extract certificate chain."
        exit 1
    }
}
Write-Host "  -> $chainFile" -ForegroundColor Green

# Build combined PEM (key first, then chain)
Write-Host "Building combined PEM..." -ForegroundColor Yellow
$keyContent   = Get-Content $keyFile   -Raw
$chainContent = Get-Content $chainFile -Raw
Set-Content -Path $combinedFile -Value ($keyContent.TrimEnd() + "`n" + $chainContent.TrimEnd() + "`n") -NoNewline
Write-Host "  -> $combinedFile" -ForegroundColor Green

# Show cert subjects in the chain for verification
Write-Host "`nCertificates in chain:" -ForegroundColor Cyan
& openssl crl2pkcs7 -nocrl -certfile $chainFile 2>$null |
    & openssl pkcs7 -print_certs -noout 2>$null |
    Select-String "subject"

Write-Host "`nDone." -ForegroundColor Green
