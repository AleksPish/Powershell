#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
  Gets list of installed features on Windows Servers
#>

#List all installed features
Get-WindowsFeature | Where-Object {$_. installstate -eq "installed"} | Format-List Name,Installstate | more

#List Features on remote host
Get-WindowsFeature -ComputerName dc01 | Where-Object {$_. installstate -eq "installed"} | Format-List Name,Installstate | more