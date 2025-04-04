#######################################
#|-----------------------------------|#
#|Aleks Piszczynski - piszczynski.com|#
#|-----------------------------------|#
#######################################
<#
.Synopsis
   Script to find details of vms that have network adapter disconnected
.DESCRIPTION
    Script to find details of vms that have network adapter disconnected. Saves output as csv to C:\temp\DisconnectedVMOutput.csv
.EXAMPLE
   connect-viserver ; Get-VMDisconnectOnBootStatus c:\temp\yourfilename.csv
#>


Function Get-VMDisconnectOnBootStatus{
    param (
        $output = "C:\temp\DisconnectedVMOutput.csv" 
    )

    $vms = Get-VM

    ForEach($vm in $vms) {
       $networkadapter =  Get-NetworkAdapter -VM $vm | Where-Object {$_.ConnectionState.StartConnected -eq $false}
        if ($null -ne $networkadapter){
        $info = [PSCustomObject]@{
            Name = $vm.Name
            Interface = $networkadapter.Name
            Type = $networkadapter.Type
            Connect_on_Boot = $networkadapter.ConnectionState.StartConnected
            }
            $info | Export-Csv $output -Append -NoTypeInformation
        }
    }
}
