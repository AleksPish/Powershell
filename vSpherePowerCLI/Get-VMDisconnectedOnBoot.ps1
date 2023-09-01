Function Get-VMDisconnectOnBootStatus{

    $vms = Get-VM 

    ForEach($vm in $vms) {
    $notconnected =  Get-NetworkAdapter -VM $vm | Where-Object {$_.ConnectionState.StartConnected -eq $True} 
 
    $info = [PSCustomObject]@{
        Name = $vm.Name
        Interface = $notconnected.Name
        Type = $notconnected.Type
        Connect_on_Boot = $notconnected.ConnectionState.StartConnected
    }

    $info | Export-Csv C:\temp\DisconnectedVMOutput.csv -Append -NoTypeInformation
    }
}