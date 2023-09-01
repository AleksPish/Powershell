#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
   Find servers that have AD connect installed in a Domain
#>

Get-ADUser -LDAPFilter "(description=*configured to synchronize to tenant*)" -Properties description | ForEach-Object { $_.description.SubString(142, $_.description.IndexOf(" ", 142) -142)}