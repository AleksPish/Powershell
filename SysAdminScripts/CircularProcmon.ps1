
Start-job{
    $h = 1
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
    
Start-job {
    $LogPath="F:\Procmon"
    $MaxLogs=5
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
        Start-Sleep 5
    
        Move-Item $Logfile F:\procmon\archive
      
    }while ($Counter -le $MaxLogs)
}
    
    