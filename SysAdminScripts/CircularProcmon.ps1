

#Script to run procmon and then save the output in a number of compressed files. Older log files will be overwritten by newer files


$Compressjob =  Start-job{
    $h = 1 #Set so process stays running

    #Gets the newly created log files and compresses them to another location, then deletes the log file
    Do {
        $pml = Get-ChildItem  -path F:\Procmon\Archive -filter *.pml
        foreach ($i in $pml){
            $dest = $i.BaseName + ".zip"
            Compress-7zip -path $i.FullName -ArchiveFileName F:\Procmon\Archive\$dest -CompressionLevel Fast
            Remove-item $i.FullName
            }
        Start-sleep 10
    }while($h = 1)
}
 Write-host "Starting compress job"
Start-Sleep 3 
Write-host $Compressjob.State

#Main process to run procmon
$MonitorJob = Start-job {
    $LogPath="F:\Procmon"
    $MaxLogs=30
    $Counter = 0
    
    
    do {          
        $Counter = $Counter+1
    
        #Reset counter if $MaxLogs is reached
        If($Counter -gt $MaxLogs)
            {
                $Counter = 1
            }
        $Logfile = $LogPath+"\Logfile_"+$counter+".pml"
        $ProcMonParameters = "/Backingfile $Logfile /AcceptEula /Minimized /Quiet"
     
        # Start ProcMon for 5 minutes
        start-process $LogPath\Procmon64.exe $ProcMonParameters
        Start-Sleep -Seconds 120

        # Terminate ProcMon
        start-process $LogPath\Procmon64.exe /Terminate
        Start-Sleep 6
        
        #Move log file to folder to be compressed
        Move-Item $Logfile F:\procmon\archive
        $Splitlogfiles = Get-ChildItem F:\Procmon -filter *.pml
        Foreach ($s in $Splitlogfiles){
        Move-Item $s.FullName F:\Procmon\Archive
        }
    }while ($Counter -le $MaxLogs)
}

Write-host "Starting monitor job"
Start-Sleep 3
write-host $MonitorJob.State

Do {
    Write-host "Press Any Key to Stop Monitoring"

    #Stops jobs if key is pressed
    if($host.UI.RawUI.ReadKey()){
        $LogPath="F:\Procmon"
        Get-Job | Stop-Job
        Write-host "Stopping Jobs"
        Start-sleep 15
        Get-Job | Remove-Job
        Write-host "Removing Jobs"
        Write-host "Stopping Procmon"
        start-process $LogPath\Procmon64.exe /Terminate
        $Compressjob.State
        $Monitorjob.State
    } 
}While ($Compressjob.State -eq "Running")
