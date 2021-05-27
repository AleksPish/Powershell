Set-Executionpolicy RemoteSigned

Function CleanLogfiles($TargetFolder, $daysToKeep = 7)
{
    write-host -debug -ForegroundColor Yellow -BackgroundColor Cyan $TargetFolder

    if (Test-Path $TargetFolder) 
    {
        $Now = Get-Date
        $LastWrite = $Now.AddDays(-$daysToKeep)
        $Files = Get-ChildItem $TargetFolder  -Recurse | Where-Object {$_.Name -like "*.log" -or $_.Name -like "*.blg" -or $_.Name -like "*.etl"}  | where {$_.lastWriteTime -le "$lastwrite"} | Select-Object FullName  

        foreach ($File in $Files)
        {
            $FullFileName = $File.FullName  
            Write-Host "Deleting file $FullFileName" -ForegroundColor "yellow"
            Remove-Item $FullFileName -ErrorAction SilentlyContinue | out-null
        }
    }
    Else 
    {
        Write-Host "The folder $TargetFolder doesn't exist! Check the folder path!" -ForegroundColor "red"
    }
}

# IIS logs
CleanLogfiles "F:\IIS\LogFiles\W3SVC1" 3
CleanLogfiles "F:\IIS\LogFiles\W3SVC2" 3

# Exchange transport logs
CleanLogfiles "F:\Exchange\Logging\Diagnostics" 3
CleanLogfiles "F:\Exchange\Logging\HttpProxy\Mapi" 3
CleanLogfiles "F:\Exchange\Logging\HttpProxy\ews" 3
CleanLogfiles "F:\Exchange\Logging\HttpProxy\eas" 3
CleanLogfiles "F:\Exchange\Logging\HttpProxy\autodiscover" 3
CleanLogFiles "F:\Exchange\Logging\MapiHttp\Mailbox" 3
CleanLogfiles "F:\Exchange\Logging\RpcHttp" 3
CleanLogfiles "F:\Exchange\Logging\Ews" 3
CleanLogfiles "F:\Exchange\Logging\CmdletInfra" 3
CleanLogfiles "F:\Exchange\Logging\NotificationBroker\Client" 3

# Allow more time for send/receive logs - these can be useful
CleanLogfiles "F:\Exchange\TransportRoles\Logs\FrontEnd\ProtocolLog\SmtpReceive" 7
CleanLogfiles "F:\Exchange\TransportRoles\Logs\FrontEnd\ProtocolLog\SmtpSend" 7