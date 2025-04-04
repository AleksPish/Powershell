#Get disks:
Get-Disk

#Get-partitions:
Get-Partition -DiskNumber <disk number>

#check for free space:
Get-Disk -Number <DiskNumber> | Select-Object Number, PartitionStyle, @{Name="UnallocatedSpaceGB";Expression={[math]::Round(($_.Size - ($_.AllocatedSize))/1GB,2)}}

# Define disk and partition numbers
$diskNumber = 1
$partitionNumber = 2

# Get the maximum supported size
$maxSize = (Get-PartitionSupportedSize -DiskNumber $diskNumber -PartitionNumber $partitionNumber).SizeMax

# Resize the partition to use all available space
Resize-Partition -DiskNumber $diskNumber -PartitionNumber $partitionNumber -Size $maxSize -Verbose

# Verify the result
Get-Partition -DiskNumber $diskNumber