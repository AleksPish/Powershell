#Get current certificate thumbprint

$thumb = (
  Get-CimInstance `
    -Namespace root\cimv2\terminalservices `
    -Class Win32_TSGeneralSetting `
    -Filter "TerminalName='RDP-tcp'"
).SSLCertificateSHA1Hash

$thumb

# Delete current certificate

Get-ChildItem Cert:\LocalMachine\My |
  Where-Object { $_.Thumbprint -eq $thumb } |
  Remove-Item

#Force Renewal
  certutil -pulse
  Restart-Service -Name "TermService" -Force