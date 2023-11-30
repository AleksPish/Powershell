#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
   Get DNS settings of list of all servers in an environment
#>
#Get list of all servers
$servers = get-ADComputer -Filter 'operatingsystem -like "*server*" -and enabled -eq "true"' | Select-Object -expandproperty name

#loop through servers to get the DNS settings of all netadapters
foreach($server in $servers){
    Invoke-Command -ComputerName $server -ScriptBlock {$adapters = Get-NetAdapter; foreach($adapter in $adapters){
        $dnsSettings = Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex
        Write-Host "$server DNS Servers: $($dnsSettings.ServerAddresses)"
    }}
}

<#
#Optional handy commands to get and change DNS on netadapters

$adapter = Get-NetAdapter; Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex

$adapterindex = (get-netadapter).ifindex; Set-DnsClientServerAddress -InterfaceIndex $adapterindex -ServerAddresses "6.0.0.57,10.10.5.4"
#>




















