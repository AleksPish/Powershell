#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
   Get All Domain Controllers
#>

function Get-DomainControllers {
    
    $domain = (get-addomain).DNSRoot
    $dcs = get-addomaincontroller -Filter * -Server $domain | Select-Object Hostname
    $dcs
}