#Get terminal server SSL certificate thumbprint
#This script retrieves the SSL certificate thumbprint for the RDP connection on a terminal server.

$thumb = (Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'").SSLCertificateSHA1Hash ; 
Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Thumbprint -eq $thumb} | Select * | fl