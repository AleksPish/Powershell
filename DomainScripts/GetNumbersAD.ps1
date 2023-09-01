#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
    Get Phone numbers from All AD Users
#>
Get-ADuser -properties * -filter * | Where-Object {$_.enabled -eq $true} | Select-Object name, samaccountname , officephone , mobilephone | export-csv