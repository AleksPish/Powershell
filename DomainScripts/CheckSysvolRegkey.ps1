#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
    Script to get all Domain controllers in a Domain and check the sysvol registry keys, this can be useful to determine an inconsistant sysvol state or replication issues.
#>

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