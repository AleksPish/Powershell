#Script to get the total number of vCPUs running on VMs in a cluster


# Connect to the vCenter Server
$vcenterServer = "mh-vs-vc-01.hosted.local"
$credential = Get-Credential
Connect-VIServer -Server $vcenterServer -Credential $credential

# Specify the cluster name
$clusterName = "MH Production MRI Apps 1"

# Get the VMs in the cluster and their CPU count
$vms = Get-Cluster -Name $clusterName | Get-VM
$cpuTotal = 0
foreach ($vm in $vms) {
    $cpuCount = $vm.NumCpu
    $cpuTotal = $cpuTotal + $cpuCount
    Write-Output "VM Name: $($vm.Name), CPU Count: $cpuCount"
}
Write-Host $cpuTotal


Connect-VIServer -Server "mh-vs-vc-01.hosted.local"
foreach ($cluster in Get-Cluster) {
    Write-Host "Cluster: $($cluster.name)"
   
    # Initialize variables for cluster-level calculations
    $TotalCPUs = 0
    $TotalAllocatedCPUs = 0
    $ClusterHostInfo = @()
 
    # Calculate total CPU counts and allocated vCPUs
    foreach ($vmhost in $cluster | Get-VMHost) {
        $TotalCPUs += $vmhost.numcpu
        $TotalAllocatedCPUs += ($vmhost | Get-VM | Measure-Object -Property numcpu -Sum).Sum
    }
   
    # Calculate the ratio of total actual vCPU allocated to the total of CPU counts
    $Ratio = $TotalAllocatedCPUs / $TotalCPUs
 
    # Display cluster-level information
    Write-Host "Total CPU counts: $TotalCPUs"
    Write-Host "Total actual vCPU allocated: $TotalAllocatedCPUs"
    Write-Host "Ratio of Total Actual vCPU Allocated to Total CPU counts: $Ratio"
    Write-Host ""
   
    # Iterate through each host in the cluster to collect host-level information
    foreach ($vmhost in $cluster | Get-VMHost) {
        # Calculate available vCPU allocation for each host
        $AvailablevCPUAllocation = ($vmhost.numcpu * 4) - ($vmhost | Get-VM | Measure-Object -Property numcpu -Sum).Sum
       
        $HostInfo = [PSCustomObject]@{
            'Host' = $vmhost.name
            'cpu count' = $vmhost.numcpu
            'Actual vCPU allocated' = ($vmhost | Get-VM | Measure-Object -Property numcpu -Sum).Sum
            'Available vCPU allocation' = $AvailablevCPUAllocation
        }
 
        # Add host-level information to the ClusterHostInfo array
        $ClusterHostInfo += $HostInfo
    }
 
    # Display host-level information
    $ClusterHostInfo | Format-Table -AutoSize
}
 
 