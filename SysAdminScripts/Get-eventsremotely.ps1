$servers = @("server1", "server2", "server3")
$command = "get-winevent -FilterHashtable @{Logname='Security';ID='4625'}"
$logfailures = foreach ($server in $servers){
    Invoke-Command -ComputerName $server -ScriptBlock { Invoke-Expression $using:command}
}