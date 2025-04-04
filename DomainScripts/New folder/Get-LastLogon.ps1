#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
   Get the last logon time from a user
#>

Function Get-LastLogon{
    # UserName
    Param($ADuser)
    $logon = (get-aduser -Identity $ADuser -Properties "lastlogon" | Select-Object lastlogon)
    $logon | Select-Object @{n='LastLogon';e={[DateTime]::FromFileTime($_.LastLogon)}}
    Write-Host $logon
}