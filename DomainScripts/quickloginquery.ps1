$logonevents = Get-Eventlog -LogName Security | where {$_.eventID -eq 4624 }
$username = <username>
Foreach ($e in $logonevents){
    if (($e.EventID -eq 4624 ) -and ($e.ReplacementStrings[5] -eq $username)){
    write-host $e}
}