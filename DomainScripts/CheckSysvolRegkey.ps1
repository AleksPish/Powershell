$domain = (get-addomain).DNSRoot
$dcs = get-addomaincontroller -Filter * -Server $domain | Select-Object Hostname
$dcs


foreach ($i in $dcs){
    $server = $i.Hostname;
    $server;
    invoke-command -computer $server{
    Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\parameters | Select-Object SysVolReady}
    }


    foreach ($i in $dcs){
        $server = $i.Hostname;
        $server;
        invoke-command -Session $server{
        Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\parameters | Select-Object SysVolReady}
        }