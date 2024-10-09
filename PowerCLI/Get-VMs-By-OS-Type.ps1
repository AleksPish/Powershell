#Script to get all vms with a specifc OS type
#Can match the OS type shown by vmware tools in the summary tab on vSphere

# Connect to your vCenter server
$vcenter = "YOUR_VCENTER_NAME"
Connect-VIServer -Server $vcenter

# Specify the folder name
$folderName = "YOUR_FOLDER_NAME"

# Get all VMs from the specified folder with Windows 2012 as the guest OS
$VMs = Get-Folder -Name $folderName | Get-VM | Where-Object { $_.Guest.OSFullName -like "Microsoft Windows Server 2012 (64-bit)" }