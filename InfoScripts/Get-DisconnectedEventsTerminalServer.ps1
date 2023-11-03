#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
  Get disconnected events from terminal server
#>

$startDate = (get-date).AddDays(-1)
$slogonevents = Get-Eventlog -LogName Microsoft-Windows-TerminalServices-LocalSessionManager/Operational -after $startDate | Where-Object {$_.eventID -eq24 }
$sloginevents | Out-GridView