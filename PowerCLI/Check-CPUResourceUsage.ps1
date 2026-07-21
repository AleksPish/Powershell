Connect-VIServer -Server "np-vs-vc-01.hosted.local" -Credential $hostedcreds
 
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
            'Host'                      = $vmhost.name
            'cpu count'                 = $vmhost.numcpu
            'Actual vCPU allocated'     = ($vmhost | Get-VM | Measure-Object -Property numcpu -Sum).Sum
            'Available vCPU allocation' = $AvailablevCPUAllocation
        }
 
        # Add host-level information to the ClusterHostInfo array
        $ClusterHostInfo += $HostInfo
    }
 
    # Display host-level information
    $ClusterHostInfo | Format-Table -AutoSize
}