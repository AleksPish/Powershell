#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
   Script to change DNS of multiple servers
.EXAMPLE
   To use create an array of the servers in the $servers variable or just use the command for a single server
#>
$servers = @()

foreach($server in $servers){
Invoke-Command -ComputerName $server -scriptblock {$adapterindex = (get-netadapter).ifindex; Set-DnsClientServerAddress -InterfaceIndex $adapterindex -ServerAddresses "1.1.1.1,8.8.8.8"}
}