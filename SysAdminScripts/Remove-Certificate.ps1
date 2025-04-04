#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
   Find certs using thumbprint and delete
#>
#For running against all servers in domain:
$Servers = get-ADComputer -Filter 'operatingsystem -like "*server*" -and enabled -eq "true"' | Select-Object -expandproperty name
 
# Input file
#$Servers = Get-Content "C:\temp\servers.txt"
#For local machine:
#$servers = $env:COMPUTERNAME
$ErrorActionPreference = 'Stop'
 
# Searching phrase
$thumbprint = Read-Host "Enter the certificate thumbprint for the certificate to delete"



function Remove-Certificate {
    param (
        $thumbprint,
        $Servers
    )
    

# Looping each server 
foreach($Server in $Servers)
{   
    Write-Host Processing $Server -ForegroundColor yellow
     
    Try
    {
        # Checking hostname of a server provided in input file 
        $hostname = ([System.Net.Dns]::GetHostByName("$Server")).hostname
   
        # Querying for certificates on remote server
        $Certs = Invoke-Command $Server -ScriptBlock{ Get-ChildItem Cert:\LocalMachine\My }
        #To run on local machine:
        #$Certs = Get-ChildItem Cert:\LocalMachine\My 
    }
    Catch
    {
        $_.Exception.Message
        Continue
    }
      
    If($hostname -and $Certs)
    {
        $deleteCerts = ($Certs | where-object {$_.Thumbprint -eq "$thumbprint"})
        Foreach($Cert in $deleteCerts)
        {
            $Cert | Remove-Item
            Write-host "$Cert Removed"
        }
    } 
    Else
    {
        Write-Warning "An Error has occurred!"
    }
}
}

Remove-Certificate $thumbprint $Servers