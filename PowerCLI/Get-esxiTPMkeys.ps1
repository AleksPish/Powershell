
#Script to get all TPM keys from ESXI servers in vSphere deployment

Connect-VIServer <vcenter hostname>

$VMHosts = get-vmhost | Sort-Object

foreach ($VMHost in $VMHosts) {
    $esxcli = Get-EsxCli -VMHost $VMHost
    try {
        $key = $esxcli.system.settings.encryption.recovery.list()
        Write-Host "$VMHost;$($key.RecoveryID);$($key.Key)"
    }

    catch {
        write-host "unable to retrieve TPM keys"
    }
foreach ($VMHost in $VMHosts) {
    $esxcli = Get-EsxCli -VMHost $VMHost
    try {
        $TPMsettings = $esxcli.system.settings.encryption.get()
        Write-Host "$VMHost;$($TPMsettings.Mode);$($TPMsettings.RequireExecutablesOnlyFromInstalledVIBs)"
    }
    catch {
        write-host "unable to retrieve TPM settings"
    }
}
}