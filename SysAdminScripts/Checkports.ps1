$ports = get-content C:\temp\ports.txt

foreach($port in $ports){
    Get-NetTCPConnection | Where-Object localport -eq $port | Sort-Object remoteaddress | Format-Table -AutoSize
}