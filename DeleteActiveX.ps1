$Count = 0
$Files = Get-ChildItem $env:userprofile -filter *noActiveX* -Recurse 
ForEach  ($File in $Files) {
    $Count++
    Remove-item $File
}
Write-host $Count" files deleted"