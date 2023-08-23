$domain = (get-addomain).DNSRoot
$dcs = get-addomaincontroller -Filter * -Server $domain | Select-Object Hostname
$dcs