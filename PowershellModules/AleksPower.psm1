<#
 .Synopsis
  A Collection of useful scripts

 .Description
  Scripts for tasks

 .Example
   # Highlight a range of days.
   Show-Calendar -HighlightDay (1..10 + 22) -HighlightDate "December 25, 2008"
#>


function Get-StoppedServices {
    Get-Service | Where-Object {$_.Status -eq "Stopped"} | More
}

New-Alias -Name gss -Value Get-StoppedServices -Description "Show all services currently in stopped state"

function Get-RunningServices {
    Get-Service | Where-Object {$_.Status -eq "Running"} | More
}

New-Alias -Name grs -Value Get-RunningServices -Description "Show all services currently in Running state"


function Get-LikeServices {
Param($name)
    Get-Service | Where-Object {$_.DisplayName -like $name} | More
}

New-Alias -Name gls -Value Get-LikeServices -Description "Get services based on DisplayName"


function Get-ADFSMO{

$ADresults = @()
$ADresults += Get-ADDomain | Select-Object InfrastructureMaster,PDCEmulator,RIDMaster
$ADresults += Get-ADForest | Select-Object DomainNamingMaster,SchemaMaster
Write-Output $ADresults | Format-List
}

New-Alias -Name adfsmo -Value Get-ADFSMO -Description "Show server hosting AD FSMO Roles"

function Remove-WinUpdateDistFolder {
    Stop-Service -Name wuauserv
    Get-Service -Name wuauserv
    Write-Host "If Service has not stopped exit script with ctrl+c and then run as admin"
    
    Pause
    for ($i=0; $i -lt 24; $i++){
    if ($i -lt 24){
    $timer = @("/","-","\","|")
        Write-Host $timer[$i%4]
        Start-Sleep -Milliseconds 150
        Clear-Host      
        }
    }
    Remove-Item -Path C:\Windows\SoftwareDistribution\* -Confirm -Force -Recurse 
    
}

New-Alias -Name delupdates -Value Remove-WinUpdateDistFolder -Description "Stop windows update service and deletes contents of software distribution folder"

function Wait-Computer
{
  Add-Type -Assembly System.Windows.Forms
  $state = [System.Windows.Forms.PowerState]::Suspend
  [System.Windows.Forms.Application]::SetSuspendState($state, $false, $false) | Out-Null
}

Export-ModuleMember -alias * -Function *