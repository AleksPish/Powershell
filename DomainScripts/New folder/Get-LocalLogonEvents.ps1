#Get all logon events from local server security logs


# Define the log name and filter
$logName = 'Security'
$filterHashtable = @{
    LogName = $logName
    Id = 4624 # Event ID for successful logon events
}

# Retrieve events
$loginEvents = Get-WinEvent -FilterHashtable $filterHashtable

# Display relevant information from each event
foreach ($event in $loginEvents) {
    $eventXML = [xml]$event.ToXml()
    $timeCreated = $event.TimeCreated
    $eventID = $event.Id
    $username = $eventXML.Event.EventData.Data | Where-Object { $_.Name -eq 'TargetUserName' }
    $logonType = $eventXML.Event.EventData.Data | Where-Object { $_.Name -eq 'LogonType' }
    $sourceIP = $eventXML.Event.EventData.Data | Where-Object { $_.Name -eq 'IpAddress' }
    
    # Output relevant information
    Write-Host "Time: $timeCreated, Event ID: $eventID, User: $($username.'#text'), Logon Type: $($logonType.'#text'), Source IP: $($sourceIP.'#text')"
}
