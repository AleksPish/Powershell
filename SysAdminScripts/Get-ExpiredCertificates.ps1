Get-ChildItem cert:\ -Recurse | Where-Object {$_ -is [System.Security.Cryptography.X509Certificates.X509Certificate2] -and $_.NotAfter -lt (Get-Date)} | Select-Object -Property FriendlyName,NotAfter