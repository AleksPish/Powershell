#Initialize all newly created and offline disks in Windows

Get-Disk  | Where-Object {$_.OperationalStatus -eq 'offline'} | Initialize-Disk -PartitionStyle GPT

#create partition on the disk
Get-Disk -Number 0 | New-Partition -UseMaximumSize -DriveLetter D 

#Format the partition and add label
Format-Volume -DriveLetter <driveletter> -FileSystem NTFS -NewFileSystemLabel "Label"