function Get-SQLServiceStatus {
    param (
        [string[]]$servers
    )
    $results = @()

    foreach ($server in $servers) {
        if (Test-Connection $server -Count 2 -Quiet) {
            $sqlServices = Get-WmiObject win32_Service -Computer $server | where-object { $_.DisplayName -match "SQL Server" }
            foreach($service in $sqlServices){
            $sqlObject = [PSCustomObject]@{
                DisplayName = $service.DisplayName
                SystemName = $service.SystemName
                State = $service.State
                Status = $service.Status
                StartMode = $service.StartMode
                StartName = $service.StartName
            }
            $results += $sqlObject   
            }           
        }
    }
    write-host "SQL services found on the following severs: $results.SystemName"
}
