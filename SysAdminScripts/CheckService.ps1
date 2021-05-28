# Enter Service name
param ([string]$global:Service)
if ($Service = $Null) {write-host "Please enter service to check"}

else{
    Write-host $Service
    while($true)
    {
    Get-Service $Service | out-file $env:Userprofile\Documents\ServiceStatus.txt -Append
    Get-date -Format "dd/MM/yyy HH:mm" | out-file $env:Userprofile\Documents\ServiceStatus.txt -Append
    Start-Sleep -Seconds 60 
    }
}