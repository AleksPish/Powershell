Get-WmiObject -Class "Win32_QuickFixEngineering" | Select -Property "Description", "HotfixID",@{Name="InstalledOn"; Expression={([DateTime]($_.InstalledOn)).ToLocalTime()}} | Sort InstalledOn -Descending
;
Get-Hotfix | Select PSComputerName, InstalledOn, Description, HotFixID, InstalledBy | Export-Csv -NoType "$Env:userprofile\Desktop\Windows Updates.csv"