$servers = get-ADComputer -Filter 'operatingsystem -like "*server*" -and enabled -eq "true"' | Select-Object -expandproperty name
 
$ErrorActionPreference = 'Stop'

foreach ($server in $servers){
    $odbclocation = Test-Path "\\$server\C$\Program Files\Microsoft SQL Server\Client SDK\ODBC"
    write-host "$server,$odbclocation"
}