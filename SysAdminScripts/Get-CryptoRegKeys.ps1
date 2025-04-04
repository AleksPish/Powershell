#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
   Script to get Registry Keys from all domain servers and return the results. 
.DESCRIPTION
   Script looks at reg keys for TLS and .NET to ensure you can identify any servers that are not compatible with secure crypto settings. Two versions are availble - comment out depending if using powershell 5 or lower. 
#>

$servers = (Get-ADComputer -Properties operatingsystem -Filter 'operatingsystem -like "*server*" -and enabled -eq "true"').Name
$returnedkeys=@()

foreach ($server in $servers) {
 
    $test = Test-Connection $server -Count 1
     
    ### Providing PowerShell 7 and 5.1 compatibility in terms of return code
     
    If ($test.Status -eq 'Success' -or $test.StatusCode -eq '0')
    {

$Returnedkeys += Invoke-Command -ComputerName $server {
$RegKeyStrongCryptov2 = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727"
$RegKeyStrongCryptov4 = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
$RegKeyStrongCryptov232bit = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727"
$RegKeyStrongCryptov432bit = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"
$RegKeySchannel11c = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"
$RegKeySchannel11s = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"
$RegKeySchannel12c = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
$RegKeySchannel12s = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"

$RVDisabledbydefault = "DisabledByDefault"
$RVEnabled = "Enabled"
$RVSystemDefaultTLSVersions = "SystemDefaultTlsVersions"
$RVSchUseStrongCrypto = "SchUseStrongCrypto"

$RegKeyStrongCryptov2Value = Get-ItemProperty -path $RegKeyStrongCryptov2 -name $RVSchUseStrongCrypto,$RVSystemDefaultTLSVersions
$RegKeyStrongCryptov4Value = Get-ItemProperty -path $RegKeyStrongCryptov4 -name $RVSchUseStrongCrypto,$RVSystemDefaultTLSVersions
$RegKeyStrongCryptov232bitValue = Get-ItemProperty -path $RegKeyStrongCryptov232bit -name $RVSchUseStrongCrypto,$RVSystemDefaultTLSVersions
$RegKeyStrongCryptov432bitValue = Get-ItemProperty -path $RegKeyStrongCryptov432bit -name $RVSchUseStrongCrypto,$RVSystemDefaultTLSVersions
$RegKeySchannel11cValue = Get-ItemProperty -path $RegKeySchannel11c -name $RVDisabledbydefault,$RVEnabled
$RegKeySchannel11sValue = Get-ItemProperty -path $RegKeySchannel11s -name $RVDisabledbydefault,$RVEnabled
$RegKeySchannel12cValue = Get-ItemProperty -path $RegKeySchannel12c -name $RVDisabledbydefault,$RVEnabled
$RegKeySchannel12sValue = Get-ItemProperty -path $RegKeySchannel12s -name $RVDisabledbydefault,$RVEnabled

$result += New-Object -TypeName PSObject -Property ([ordered]@{ 
    'Server' = $env:computername
    '.NETv2' = $RegKeyStrongCryptov2Value
    '.NETv4' = $RegKeyStrongCryptov4Value
    '.NET32bit' = $RegKeyStrongCryptov232bitValue
    '.NET64bit' = $RegKeyStrongCryptov432bitValue
    'TLS1.1 Client' = $RegKeySchannel11cValue
    'TLS1.1 Server' = $RegKeySchannel11sValue
    'TLS1.2 Client' = $RegKeySchannel12cValue
    'TLS1.2 Server' = $RegKeySchannel12sValue
    }
    )
    Write-output $result
}
}
}
$returnedkeys | out-file -append -FilePath C:\temp\Servercryptokeys.txt


<#
$servers = (Get-ADComputer -Properties operatingsystem `
-Filter 'operatingsystem -like "*server*" -and enabled -eq "true"').Name
 
### Collection Point
 


foreach ($item in $servers) {
 
    $test = Test-Connection $item -Count 1
     
    ### Providing PowerShell 7 and 5.1 compatibility in terms of return code
     
    If ($test.Status -eq 'Success' -or $test.StatusCode -eq '0')
    {
    $result = @()
    $RegKeyStrongCryptov2 = Invoke-Command -ComputerName $item { Get-ItemPropertyValue -path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727" -name $RVSchUseStrongCrypto}
    $RegKeyStrongCryptov4 = Invoke-Command -ComputerName $item { Get-Item "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"}
    $RegKeyStrongCryptov232bit = Invoke-Command -ComputerName $item { Get-Item "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727"}
    $RegKeyStrongCryptov432bit = Invoke-Command -ComputerName $item { Get-Item "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"}
    $RegKeySchannel11c = Invoke-Command -ComputerName $item { Get-Item "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"}
    $RegKeySchannel11s = Invoke-Command -ComputerName $item { Get-Item "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"}
    $RegKeySchannel12c = Invoke-Command -ComputerName $item { Get-Item "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"}
    $RegKeySchannel12s = Invoke-Command -ComputerName $item { Get-Item "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"}
$result += $item,$RegKeyStrongCryptov2,$RegKeyStrongCryptov4,$RegKeyStrongCryptov232bit,$RegKeyStrongCryptov432bit,$RegKeySchannel11c,$RegKeySchannel11s,$RegKeySchannel12c,$RegKeySchannel12s
$result | Out-File c:\temp\cryptoregkeys.txt
    }
    }


    $RegKeyStrongCryptov2 = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727"
    $RegKeyStrongCryptov4 = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
    $RegKeyStrongCryptov232bit = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727"
    $RegKeyStrongCryptov432bit = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"
    $RegKeySchannel11c = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"
    $RegKeySchannel11s = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"
    $RegKeySchannel12c = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
    $RegKeySchannel12s = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"


$RVDisabledbydefault = "DisabledByDefault"
$RVEnabled = "Enabled"
$RVSystemDefaultTLSVersions = "SystemDefaultTlsVersions"
$RVSchUseStrongCrypto = "SchUseStrongCrypto"


Invoke-Command -ComputerName $server {
$RegKeyStrongCryptov2Value = Get-ItemPropertyValue -path $RegKeyStrongCryptov2 -name $RVSchUseStrongCrypto,$RVSystemDefaultTLSVersions
$RegKeyStrongCryptov4Value = Get-ItemPropertyValue -path $RegKeyStrongCryptov4 -name $RVSchUseStrongCrypto,$RVSystemDefaultTLSVersions
$RegKeyStrongCryptov232bitValue = Get-ItemPropertyValue -path $RegKeyStrongCryptov232bit -name $RVSchUseStrongCrypto,$RVSystemDefaultTLSVersions
$RegKeyStrongCryptov432bitValue = Get-ItemPropertyValue -path $RegKeyStrongCryptov432bit -name $RVSchUseStrongCrypto,$RVSystemDefaultTLSVersions
$RegKeySchannel11cValue = Get-ItemPropertyValue -path $RegKeySchannel11c -name $RVDisabledbydefault,$RVEnabled
$RegKeySchannel11sValue = Get-ItemPropertyValue -path $RegKeySchannel11s -name $RVDisabledbydefault,$RVEnabled
$RegKeySchannel12cValue = Get-ItemPropertyValue -path $RegKeySchannel12c -name $RVDisabledbydefault,$RVEnabled
$RegKeySchannel12sValue = Get-ItemPropertyValue -path $RegKeySchannel12s -name $RVDisabledbydefault,$RVEnabled
}

<#
$RegKeyStrongCryptov2Value
$RegKeyStrongCryptov4Value
$RegKeyStrongCryptov232bitValue
$RegKeyStrongCryptov432bitValue
$RegKeySchannel11cValue
$RegKeySchannel11sValue
$RegKeySchannel12cValue
$RegKeySchannel12sValue

New-Object -TypeName PSObject -Property ([ordered]@{
 
    'Server' = $server
    '.NETv2' = $RegKeyStrongCryptov2Value
    '.NETv4' = $RegKeyStrongCryptov4Value
    '.NET32bit' = $RegKeyStrongCryptov232bitValue
    '.NET64bit' = $RegKeyStrongCryptov432bitValue
    'TLS1.1 Client' = $RegKeySchannel11cValue
    'TLS1.1 Server' = $RegKeySchannel11sValue
    'TLS1.2 Client' = $RegKeySchannel12cValue
    'TLS1.2 Server' = $RegKeySchannel12sValue
    }
    )

#>