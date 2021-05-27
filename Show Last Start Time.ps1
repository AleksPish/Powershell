Get-WmiObject Win32_OperatingSystem -ComputerName $env:COMPUTERNAME | Select-Object @{Name = 'LastStartTime' ; Expression = {[Management.ManagementDateTimeConverter]::ToDateTime($_.LastBootUpTime)}}
