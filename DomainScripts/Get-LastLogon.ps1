Function Get-LastLogon{
    # UserName
    Param($ADuser)
    $logon = (get-aduser -Identity $ADuser -Properties "lastlogon" | select lastlogon)
    $logon | select @{n='LastLogon';e={[DateTime]::FromFileTime($_.LastLogon)}}
    Write-Host $logon
}