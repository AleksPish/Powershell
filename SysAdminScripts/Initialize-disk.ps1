#Show Disks
Get-Disk

#Bring Disk Online
Set-Disk -Number <DiskNumber> -IsOffline $false

#Initialize disk
Initialize-Disk -Number <DiskNumber> -PartitionStyle GPT

#Create Partition
New-Partition -DiskNumber <DiskNumber> -UseMaximumSize -DriveLetter <DriveLetter>

#Format Partition
Format-Volume -DriveLetter <DriveLetter> -FileSystem NTFS -NewFileSystemLabel "<VolumeLabel>" -Confirm:$false

#Check New Volume
Get-Volume -DriveLetter <DriveLetter> | Format-Table -AutoSize