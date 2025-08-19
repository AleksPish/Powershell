# Specify vCenter Server, vCenter Server prompts for username and vCenter Server user password
$vCenter="vcenter.domain.local"
 
# Get local execution path
$localpath = Get-Location
 
Write-Host "Connecting to vCenter Server $vCenter" -foreground green
Connect-viserver $vCenter -WarningAction 0
 
# Get list of all ESXi hosts known by vCenter
$AllVMHosts =  Get-VMHost
 
ForEach ($VMHost in $AllVMHosts)
{
    Write-Host " "
    Write-Host "Backing Up Host Configuration: $VMHost" -foreground green
    Get-VMHostFirmware -VMHost $VMHost -BackupConfiguration -DestinationPath $localpath
}
 
Write-Host
Write-Host "Files Saved to: $localpath";
Write-Host
Write-Host "Press any key to close ..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
