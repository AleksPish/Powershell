#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
   Get all ports a server is listening on and display the owning process
#>

function Get-ListeningProcesses {

    $listenports = Get-NetTCPConnection | Where-Object {$_.state -eq "Listen"}

    $portinfo = @()

    $listenports | ForEach-Object {$localport = $_.LocalPort ;

        $processname = Get-process -id $_.OwningProcess;

        $portdetails = [PSCustomObject]@{
        LocalPort = $localport
        ProcessName = $processname.ProcessName
    }
    $portdetails
    $portinfo += $portdetails
    }
    $portinfo
}
$export = Get-ListeningProcesses
$export | Export-Csv "C:\Temp\$env:COMPUTERNAME ListeningPorts.csv"