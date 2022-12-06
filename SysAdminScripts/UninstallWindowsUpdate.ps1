# Get a list of installed Windows updates
$updates = Get-WmiObject -Class Win32_QuickFixEngineering | Sort-Object -Property InstalledOn -Descending

# Uninstall the last update in the list
$updates[0].Uninstall()