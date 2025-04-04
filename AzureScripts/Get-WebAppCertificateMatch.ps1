#gets the hostnames of the webapps to allow checking for bound certificates

Get-AzWebApp | Where-Object { $_.HostNames -like "<add hostname/domain/cert here>" } | Select-Object RepositorySiteName, DefaultHostName, ResourceGroup
