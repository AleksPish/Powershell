<#
 .Synopsis
  A Collection of useful scripts

 .Description
  Scripts for tasks

 .Example
   You don't need any examples
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
    for ($i=0; $i -lt 24; $i++){
    if ($i -lt 24){
    $timer = @("/","-","\","|")
        Write-Host $timer[$i%4]
        Start-Sleep -Milliseconds 150
        Clear-Host      
        }
    }
    Get-Service -Name wuauserv
    Write-Host "If Service has not stopped exit script with ctrl+c and then run as admin"
    
    Pause
    
    Remove-Item -Path C:\Windows\SoftwareDistribution\* -Confirm -Force -Recurse 
    
}
New-Alias -Name delupdates -Value Remove-WinUpdateDistFolder -Description "Stop windows update service and deletes contents of software distribution folder"

function DeleteActiveX {
    $Count = 0
    $Files = Get-ChildItem $env:userprofile -filter *noActiveX* -Recurse 
    ForEach  ($File in $Files) {
        $Count++
        Remove-item $File -ErrorAction SilentlyContinue
    }
    Write-host -ForegroundColor Green $Count" files deleted"
}

function DeleteISLlight {
    $Count = 0
    $Files = Get-ChildItem $env:userprofile -filter *"ISL Light"* -Recurse 
    ForEach  ($File in $Files) {
        $Count++
        Remove-item $File
    }
    Write-host $Count" files deleted"
}

function Update-Powershell {
    Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI"
}

function Wait-Computer
{
  Add-Type -Assembly System.Windows.Forms
  $state = [System.Windows.Forms.PowerState]::Suspend
  [System.Windows.Forms.Application]::SetSuspendState($state, $false, $false) | Out-Null
}

function Get-SimpleFoldersizes {
    
    # Get the folders and sort  
    $Folders = (Get-ChildItem | Where-Object {$_.PSIsContainer -eq $True} | Sort-Object)
    
    #Get info on each folder and input to PSobject
    foreach ($i in $Folders)
        {
            $subFolderItems = (Get-ChildItem $i.FullName -recurse | Measure-Object -property length -sum)
            $size = ($subFolderItems.sum / 1MB)
             
            Write-host $i.Name , $size
        }  
    }


    function Get-AleksPower {
        $userProfilePath = $env:userprofile
        $test = Test-Path  -Path $env:userprofile\Documents\PowerShell\Modules\AleksPower
        if ($test -eq $false){
            Write-Host -ForegroundColor Yellow "Creating Folder"
            New-Item -Path $env:userprofile\Documents\PowerShell\Modules\AleksPower -ItemType Directory
            Write-Host -ForegroundColor Yellow "Downloading"
            Invoke-WebRequest -Uri https://raw.githubusercontent.com/AleksPish/Powershell/master/PowershellModules/AleksPower.psm1 -UseBasicParsing -OutFile $userProfilePath\Documents\PowerShell\Modules\AleksPower\AleksPower.psm1
            Write-Host -ForegroundColor Green "Complete"
        }
        else {
        Write-Host -ForegroundColor Yellow "Downloading"
        Invoke-WebRequest -Uri https://raw.githubusercontent.com/AleksPish/Powershell/master/PowershellModules/AleksPower.psm1 -UseBasicParsing -OutFile $userProfilePath\Documents\PowerShell\Modules\AleksPower\AleksPower.psm1
        Write-Host -ForegroundColor Green "Complete"
    }
    }

    function Enter-Task {
        param (
            [string]$id,
            [string]$update
        )
        $date = (get-date).ToLongDateString()
        $fileCheck = test-path "$env:USERPROFILE\Documents\Tasks\$date.csv"
        $file = "$env:USERPROFILE\Documents\Tasks\$date.csv"
        if ($false -eq $fileCheck){
            New-Item -ItemType "File" -Path "$env:USERPROFILE\Documents\Tasks\$date.csv"
        }
        if([String]::IsNullOrWhiteSpace((Get-content $file))) {
            $lastTaskTime = (Get-Date -Format HH:mm:ss)
            $header = "ID,Note,Minutes,Time"
            $header | out-file -path $file -append
        }
        else {
            $lastTaskFile = Import-Csv $file 
            $lastTaskEntry = $lastTaskFile[$lastTaskFile.Count -1]
            $lastTaskTimeEntry = $lastTaskEntry.PSObject.Properties.Name[-1]
            $lastTaskTime = $lastTaskEntry.$lastTaskTimeEntry
        }
        $timestamp = (Get-Date -Format HH:mm:ss)
        $timeTaken = New-Timespan -Start $lastTaskTime -End $timestamp 
        $timeTakenInMinutes = [Math]::Round($timeTaken.TotalMinutes)
        $output = "$id,$update,$timeTakenInMinutes,$timestamp"
        $output | Out-file  -Append -Path $file
    }

New-Alias -Name et -Value Enter-Task -Description "Enter a string or comment into a text file for recording tasks or notes with a timestamp"

Export-ModuleMember -alias * -Function *