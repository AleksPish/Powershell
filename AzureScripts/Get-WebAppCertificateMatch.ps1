

Get-AzWebApp | Where-Object { $_.HostNames -like "<add hostname/domain/cert here>" } | Select-Object RepositorySiteName, DefaultHostName, ResourceGroup
