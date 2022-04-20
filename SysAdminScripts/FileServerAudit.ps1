<#
.SYNOPSIS
This script uses two functions named Get-Inventory and Get-FolderItem and the ImportExcel module which require installing 
before being able to run other scripts and commands to generate an xlsx spreadsheet which gathers information on a FileServer without having 
to use the Excel COM Model (i.e. you don't have to install Excel on the machine). Therefore Run PowerShell as an Administrator 
to install the required modules or add the -scope CurrentUser parameter to the Install-Module command.
.DESCRIPTION 
Generates a list of information in xlsx format for the following
ServerInformation
DiskInformation
FilesByTypePerDir
Over260Characters
CreatedLastAccessModified
SystemLogCriticalErrorsWarnings
AppLogCriticalErrorsWarnings
#>


# Install the ImportExcel Module from the PS Gallery. NOTE: Comment this install out if the module is already installed.
Install-Module ImportExcel -Force
Import-Module ImportExcel -Force
<#
Create a variable for the xlsx file that we're going to create with our various worksheets in. The run the Get-Inventory 
function and pipe to Export-Excel whilst changing the worksheet name to ServerInformation and setting the AutoSize and 
AutoFilter parameters.
NOTE The ImportExcel Module has a number of components within it such as Import-Excel, Export-Excel so it can be confusing 
when reading the help. Just be mindful of hyphens etc reference cmdlets whereas unhyphenated names reference a module.
#>
$FileServerAudit = "C:\FSA\FileServerAudit.xlsx"
. .\Get-Inventory.ps1 | Export-Excel -Path $FileServerAudit -WorkSheetName ServerInformation -Autosize -AutoFilter; 

<#  
We need a worksheet for each of the following, so we populate with sheets relevant to our various import tasks.
ServerInformation
DiskInformation
FilesByTypePerDir
Over260Characters
CreatedLastAccessModified
SystemLogCriticalErrorsWarnings
AppLogCriticalErrorsWarnings
Create a new variable with the same previous name, and Open the spreadsheet using the Open-ExcelPackage and add more 
worksheets, then close to save. Add the -Show after the Close-ExcelPackage $FileServerAudit variable to verify that it 
appears in Excel when opened. 
#>
$FileServerAudit = Open-ExcelPackage -Path "C:\FSA\FileServerAudit.xlsx"
Add-WorkSheet $FileServerAudit -WorksheetName DiskInformation
Add-WorkSheet $FileServerAudit -WorksheetName EncryptionInformation
Add-WorkSheet $FileServerAudit -WorksheetName FileCountPerDir
Add-WorkSheet $FileServerAudit -WorksheetName FilesByTypePerDir
Add-WorkSheet $FileServerAudit -WorksheetName Over260Characters
Add-WorkSheet $FileServerAudit -WorksheetName CreatedLastAccessModified
Add-WorkSheet $FileServerAudit -WorksheetName SystemLogCriticalErrorsWarnings
Add-WorkSheet $FileServerAudit -WorksheetName AppLogCriticalErrorsWarnings
<#
Add the Get-FolderItem Function. This Powershell script needs to be in the same directory that this script is run from. 
Note this has to be dot sourced, therefore do not remove the first period and space before the path to the ps1 file. We also create the 
variable again as it gets removed from the pipeline when the excel package is closed off. 
#>
$FileServerAudit = "C:\FSA\FileServerAudit.xlsx"
. .\Get-FolderItem.ps1
<# 
Create a variable for the Get-ChildItem path specified and then pipe to the Get-Folder itme function. NOTE: Output may 
show warnings for files as it is getting a count of files per directory and files will be read as not a directory, 
therefore generating a warning! By design behaviour
#>
$files = Get-ChildItem -Path "E:\User Profiles\Documents"| Get-FolderItem
$files | Group-Object ParentFolder | Select-Object Count,Name | Export-Excel -Path $FileServerAudit -WorkSheetName FileCountPerDir -Autosize -AutoFilter

<# Get the last 100 entries in the System log that are either critical, error or warnings and use the following columns 
LevelDisplayName, TimeCreated, ProviderName, Id, TaskDisplayName, then export into the SystemLogCriticalErrorsWarnings worksheet.
#>
Get-WinEvent -FilterHashtable @{logname='system'; level=1,2,3} -MaxEvents 100 | Select-Object LevelDisplayName, TimeCreated, ProviderName, Id, TaskDisplayName | 
Export-Excel -Path $FileServerAudit -WorkSheetName SystemLogCriticalErrorsWarnings -Autosize -AutoFilter

<# Get the last 100 entries in the Application log that hare either critical, error or warnings and use the following columns 
LevelDisplayName, TimeCreated, ProviderName, Id, TaskDisplayName, then export into the AppLogCriticalErrorsWarnings worksheet.
#>
Get-WinEvent -FilterHashtable @{logname='application'; level=1,2,3} -MaxEvents 100 | Select-Object LevelDisplayName, TimeCreated, ProviderName, Id, TaskDisplayName | 
Export-Excel -Path $FileServerAudit -WorkSheetName AppLogCriticalErrorsWarnings -Autosize -AutoFilter

<# 
Get Directories over 260 Characters in length for the [path specified. Create multiple copies if there are more than one drive 
or you want to target specific directories.
#>
Set-Location "E:\User Profiles\Documents"
cmd /c "dir /b /s /a" | ForEach-Object { if ($_.length -gt 260) {$_ | Export-Excel -Path $FileServerAudit -WorkSheetName Over260Characters -Autosize -AutoFilter -Append}}

<# 
Get FilesbyType Count for the directory where the command is run, then group by extension and count and order largest first, 
then export into the FilesByTypePerDir worksheet.Create multiple copies if there are more than one drive or you want to target specific directories.
#>
Set-Location "E:\User Profiles\Documents"
Get-ChildItem -Recurse | Where-Object { -not $_.PSIsContainer } | Group-Object Extension -NoElement | Select-Object Count,Name | Sort-Object count -desc | 
Export-Excel -Path $FileServerAudit -WorkSheetName FilesByTypePerDir -Autosize -AutoFilter -Append

<#
Get disk Encryption Information
#>
Get-BitLockerVolume | Export-Excel -Path $FileServerAudit -WorkSheetName EncryptionInformation -MoveAfter ServerInformation -Autosize -AutoFilter -Append
<# 
Get the disk information using fsutil and export into the DiskInformation worksheet.
#>
cmd /c "fsutil fsinfo ntfsinfo c:" | ConvertFrom-String -Delimiter ":" | Export-Excel -Path $FileServerAudit -WorkSheetName DiskInformation -Autosize -AutoFilter -Append
cmd /c "fsutil volume filelayout c:\$mft" | ConvertFrom-String -Delimiter ":" | Export-Excel -Path $FileServerAudit -WorkSheetName DiskInformation -Autosize -AutoFilter -Append

<# 
Get the NtfsMftZoneReservation registry Key and export into the DiskInformation worksheet.
#>
Set-Location HKLM:
Get-ItemProperty -Path HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem -Name NtfsMftZoneReservation | 
Export-Excel -Path $FileServerAudit -WorkSheetName DiskInformation -MoveAfter ServerInformation -Autosize -AutoFilter -Append
<# 
Get a list of Created Last Access and Modified Times and export to the CreatedLastAccessModified worksheet.
#>
Set-Location "E:\User Profiles\Documents"
Get-ChildItem -Recurse | Select-Object FullName,CreationTime,LastWriteTime,LastAccessTime | 
Export-Excel -Path $FileServerAudit -WorkSheetName CreatedLastAccessModified -Autosize -AutoFilter -Append 


# Optimize-Volume -Driveletter D -Analyze -Verbose | Export-Excel -Path $FileServerAudit -WorkSheetName DiskInformation -Autosize -AutoFilter -Append 
