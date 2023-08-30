$Inventory = New-Object System.Collections.ArrayList
$AllComputers = Get-Content C:\temp\ntptest.txt
foreach($Computers in $Allcomputers){
  $Computers

  $ComputerInfo = New-Object System.Object
  $ntp = w32tm /query /computer:$Computers /source

  $ComputerInfo |Add-Member -MemberType NoteProperty -Name "ServerName" -Value "$Computers"
  $ComputerInfo |Add-Member -MemberType NoteProperty -Name "NTP Source" -Value "$Ntp"

  $Inventory.Add($ComputerInfo) | Out-Null
  }

$Inventory | Export-Csv C:\temp\NTP.csv -NoTypeInformation