#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
   Get the time offset from a list of servers using the windows time service

#>
#Create list of servers
$servers=@(
    "server1",
    "server2"
)

foreach($server in $servers){
    #Display current server being tested
Write-host $server "Time offset:"
#Check the time offset on the server remotely using w32tm service
invoke-command -computer $server -ScriptBlock {Invoke-Expression "w32tm /stripchart /computer:<TimeServer> /samples:1"} -ErrorAction SilentlyContinue
}
