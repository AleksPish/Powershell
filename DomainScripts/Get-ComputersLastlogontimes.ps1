#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
   Get the last logon time from devices in a specific OU
#>

$OU = "OU=Workstations,DC=domainName,DC=local"

$workstations = Get-ADComputer -Filter * -SearchBase $OU -Properties lastLogon

$workstationinfo = @()

$workstations | ForEach-Object{
    $results = [PSCustomObject]@{
    dnsname = $_.DNSHostName
    lastLogon = ([DateTime]::FromFileTime($_.LastLogon))
        }
    $workstationinfo = $workstationinfo += $results
}
$workstationinfo