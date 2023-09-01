#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
   Function to download the AleksPower powershell module and place in user powershell modules folder
#>

function Get-AleksPower {
    $userProfilePath = $env:userprofile
    $test = Test-Path  -Path $env:userprofile\Documents\PowerShell\Modules\AleksPower
    if ($test -eq $false){
        New-Item -Path $env:userprofile\Documents\PowerShell\Modules\AleksPower -ItemType Directory
        Invoke-WebRequest -Uri https://raw.githubusercontent.com/AleksPish/Powershell/master/PowershellModules/AleksPower.psm1 -UseBasicParsing -OutFile $userProfilePath\Documents\PowerShell\Modules\AleksPower\AleksPower.psm1
    }
    else {
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/AleksPish/Powershell/master/PowershellModules/AleksPower.psm1 -UseBasicParsing -OutFile $userProfilePath\Documents\PowerShell\Modules\AleksPower\AleksPower.psm1
    }
}