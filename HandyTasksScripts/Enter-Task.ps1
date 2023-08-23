function Enter-Task {
    param (
        [string]$id,
        [string]$update
    )
    $date = (get-date).ToLongDateString()
    $fileCheck = test-path "$env:USERPROFILE\Documents\Tasks\$date.csv"
    $file = "$env:USERPROFILE\Documents\Tasks\$date.csv"
    if ($false -eq $fileCheck){
        New-Item -ItemType "File" -Path "$env:USERPROFILE\Documents\Tasks\$date.csv"
    }
    if([String]::IsNullOrWhiteSpace((Get-content $file))) {
        $lastTaskTime = (Get-Date -Format HH:mm:ss)
        $header = "ID,Note,Minutes,Time"
        $header | out-file -path $file -append
    }
    else {
        $lastTaskFile = Import-Csv $file 
        $lastTaskEntry = $lastTaskFile[$lastTaskFile.Count -1]
        $lastTaskTimeEntry = $lastTaskEntry.PSObject.Properties.Name[-1]
        $lastTaskTime = $lastTaskEntry.$lastTaskTimeEntry
    }
    $timestamp = (Get-Date -Format HH:mm:ss)
    $timeTaken = New-Timespan -Start $lastTaskTime -End $timestamp 
    $timeTakenInMinutes = [Math]::Round($timeTaken.TotalMinutes)
    $output = "$id,$update,$timeTakenInMinutes,$timestamp"
    $output | Out-file  -Append -Path $file
}


