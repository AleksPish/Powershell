$ReferencePath = Read-Host -Prompt "Enter directory to get folder names from"
$TargetFolder = Read-Host -Prompt "Enter folder to remove folders from"

Write-Warning "Folders will be deleted from this location: $TargetFolder Do you wish to continue?" -WarningAction Inquire
if ((Test-Path -path $ReferencePath -PathType Any) -and (Test-Path -path $TargetFolder -PathType Any))
{
$Reference = Get-ChildItem -path $ReferencePath | Select-Object -Property Name
$target = $TargetFolder
foreach ($Folder in $Reference){
    $path = $Folder.Name
    if (Test-Path -path "$target\$path"-PathType Any){
    Remove-Item -Force -Recurse -Path "$target\$path"
    write-host $path" deleted"
    } Else{
        Write-host "$target\$path not found"
    }
}
}
else {
    Write-Host "Target or reference folder not found"
}