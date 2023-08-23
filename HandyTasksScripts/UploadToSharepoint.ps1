##requires -Modules PnP.PowerShell

<#PSScriptInfo
.VERSION 1.0
.GUID ef784154-99b9-492c-86a6-70dae59d66b1
.AUTHOR June Castillote
.COMPANYNAME
.COPYRIGHT
.TAGS
.LICENSEURI
.PROJECTURI
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>

<#
.DESCRIPTION
 meh
.EXAMPLE
Non-recursive (top-folder only) upload.
$Credentials = Get-Credentials
.\Start-FolderUpload.ps1 `
    -Credentials $Credentials `
    -SiteUrl 'https://tenant.sharepoint.com/sites/sitename' `
    -TargetFolderName 'Shared Documents' `
    -LocalFolderPath 'C:\FolderToUpload'
.EXAMPLE
Recursive (all subfolders and files) upload.
$Credentials = Get-Credentials
.\Start-FolderUpload.ps1 `
    -Credentials $Credentials `
    -SiteUrl 'https://tenant.sharepoint.com/sites/sitename' `
    -TargetFolderName 'Shared Documents' `
    -LocalFolderPath 'C:\FolderToUpload' `
    -Recursive
#>



[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [pscredential]
    $Credentials,
    [Parameter(Mandatory)]
    [string]
    $SiteUrl,
    [Parameter(Mandatory)]
    [string]
    $LocalFolderPath,
    [Parameter(Mandatory)]
    [string]
    $TargetFolderName,
    [Parameter()]
    [Switch]
    $Recursive
)

# Ensure that the LocalFolderPath exists. Exit if not.
if (!$(Test-Path $LocalFolderPath)) {
    "The LocalFolderPath does not exist." | Out-Default
    return $null
}

# Connect to the SPO site. Exit if failed.
try {
    Connect-PnPOnline -Url $SiteUrl -Credentials $Credentials -ErrorAction STOP
}
catch {
    $_.Exception.Message | Out-Default
    return $null
}

# Ensure that the Document Library exists. Exit if not.
try {
    $null = Resolve-PnPFolder -SiteRelativePath $TargetFolderName -ErrorAction Stop
}
catch {
    $_.Exception.Message | Out-Default
    return $null
}

# Upload the top-level folder files only.
$Files = Get-ChildItem -Path $LocalFolderPath -File
foreach ($File in $Files) {
    Add-PnPFile -Path ($File.FullName.ToString()) -Folder $TargetFolderName -Values @{"Title" = $($File.Name) } | Out-Null
    "Uploaded File: $($File.FullName)" | Out-Default
}

# If -Recursive, upload the subfolders and files
if ($Recursive) {
    $SubFolders = Get-ChildItem -Path $LocalFolderPath -Directory -Recurse
    foreach ($SubFolder in $SubFolders) {
        $SubTargetFolderName = "$($TargetFolderName)$(($SubFolder.FullName).Replace($LocalFolderPath,'').Replace('\','/'))"
        $Files = Get-ChildItem -Path ($SubFolder.FullName) -File
        foreach ($File in $Files) {
            Add-PnPFile -Path ($File.FullName.ToString()) -Folder $SubTargetFolderName -Values @{"Title" = $($File.Name) } | Out-Null
            "Uploaded File: $($File.FullName)" | Out-Default
        }
    }
}