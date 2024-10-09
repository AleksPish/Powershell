#Script to get the total number of vCPUs running on VMs in a cluster


# Connect to the vCenter Server
$vcenterServer = "<vcenter server hostname>"
$credential = Get-Credential
Connect-VIServer -Server $vcenterServer -Credential $credential

# Specify the cluster name
$clusterName = "<cluster name>"

# Get the VMs in the cluster and their CPU count
$vms = Get-Cluster -Name $clusterName | Get-VM
$cpuTotal = 0
foreach ($vm in $vms) {
    $cpuCount = $vm.NumCpu
    $cpuTotal = $cpuTotal + $cpuCount
    Write-Output "VM Name: $($vm.Name), CPU Count: $cpuCount"
}
Write-Host $cpuTotal


