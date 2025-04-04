# Define the log name
$logName = "Security"

# Define the event ID for user logins
$eventID = 4624

# Initialize an empty array to store the objects
$loginEvents = @()
# Calculate the time 24 hours ago
$startDate = (Get-Date).AddDays(-1)

# Get the events from the Security log with the specified Event ID
$events = Get-WinEvent -FilterHashtable @{LogName=$logName; ID=$eventID; StartTime=$startDate} -ErrorAction SilentlyContinue

# Check if there are any events found
if ($events) {
    # Iterate through each event
    foreach ($event in $events) {
        # Extract relevant information from the event
        $timeCreated = $event.TimeCreated
        $userName = $event.Properties[5].Value
        $logonType = $event.Properties[8].Value
        $sourceNetworkAddress = $event.Properties[18].Value
        $authenticationPackage = $event.Properties[9].Value

        # Create a custom object for the event
        $loginEventObject = [PSCustomObject]@{
            TimeCreated = $timeCreated
            UserName = $userName
            LogonType = $logonType
            SourceNetworkAddress = $sourceNetworkAddress
            AuthenticationPackage = $authenticationPackage
        }

        # Add the object to the array
        $loginEvents += $loginEventObject
    }
} else {
    Write-Host "No user login events found in the Security log."
}

# Output the array of login event objects
$loginEvents

#Export to a csv file
$loginEvents | Export-Csv C:\Temp\Loginevents.csv