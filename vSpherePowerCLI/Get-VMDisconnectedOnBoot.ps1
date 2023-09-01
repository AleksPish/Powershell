#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
   Get List of VMs in vSphere that have the connected on boot option set to false
#>

Function Get-VMDisconnectOnBootStatus{
    #Get VMs
    $vms = Get-VM 
    #Iterate through VMs to find connection state and output to file
    ForEach($vm in $vms) {
    $notconnected =  Get-NetworkAdapter -VM $vm | Where-Object {$_.ConnectionState.StartConnected -eq $False} 
        If($notconnected.ConnectionState.StartConnected -eq $false) {
        $info = [PSCustomObject]@{
            Name = $vm.Name
            Interface = $notconnected.Name
            Type = $notconnected.Type
            Connect_on_Boot = $notconnected.ConnectionState.StartConnected
            }
        $info | Export-Csv C:\temp\DisconnectedVMOutput.csv -Append -NoTypeInformation
        }
    }   
}