Connect-VIServer -server <FQDN of vsphere or host>

Set-PowerCLIConfiguration -InvalidCertificateAction Prompt

Get-VM | Get-CDDrive | where{$_.IsoPath -match '<name of iso image>'} | Select @{N='VM';E={$_.Parent.Name}},Name,IsoPath