$servers=@(
    "server1",
    "server2"
)

foreach($server in $servers){
Write-host $server "Time offset:"
invoke-command -computer $server -ScriptBlock {Invoke-Expression "w32tm /stripchart /computer:<TimeServer> /samples:1"} -ErrorAction SilentlyContinue
}
