<# 

.SYNOPSIS

    Review RDS logons (success & failure) across an RD Collection within a time frame.
 
.DESCRIPTION

    - Uses the RD Connection Broker to enumerate Session Hosts in a collection.

    - Queries each host's Security log for Event IDs 4624 (success) & 4625 (failure)

      filtered to LogonType = 10 (RemoteInteractive / RDP).

    - Outputs a clean table (and optional CSV) with TimeCreated, EventType, User, Domain,

      SourceIP, SessionHost, LogonID, AuthPackage, and more.
 
.PARAMETER Broker

    FQDN of the RD Connection Broker (e.g. rdbroker.contoso.local)
 
.PARAMETER CollectionName

    RD Session Collection name to limit which hosts to query. If omitted, all RD Session Hosts

    known to the Broker are queried.
 
.PARAMETER StartTime

    Beginning of the time window. Defaults to (Get-Date).AddDays(-1)
 
.PARAMETER EndTime

    End of the time window. Defaults to (Get-Date)
 
.PARAMETER UserLike

    Optional filter to include only users whose samAccountName *contains* this string.
 
.PARAMETER ExportCsvPath

    Optional file path to export results as CSV.
 
.EXAMPLE

    .\Get-RDS-Logons.ps1 -Broker "rdbroker.contoso.local" `

        -CollectionName "HQ Apps" -StartTime "2025-09-03 00:00" -EndTime "2025-09-04 00:00" `

        -ExportCsvPath "C:\Temp\RDS-Logons.csv"
 
.EXAMPLE

    Last 4 hours for any user containing "jsmith":

    .\Get-RDS-Logons.ps1 -Broker rdbroker.contoso.local -StartTime (Get-Date).AddHours(-4) -UserLike jsmith

#>
 
[CmdletBinding()]

param(

    [Parameter(Mandatory=$true)]

    [string]$Broker,
 
    [Parameter(Mandatory=$false)]

    [string]$CollectionName,
 
    [Parameter(Mandatory=$false)]

    [datetime]$StartTime = (Get-Date).AddDays(-1),
 
    [Parameter(Mandatory=$false)]

    [datetime]$EndTime = (Get-Date),
 
    [Parameter(Mandatory=$false)]

    [string]$UserLike,
 
    [Parameter(Mandatory=$false)]

    [string]$ExportCsvPath

)
 
function Get-RDSessionHostsFromBroker {

    param(

        [string]$Broker,

        [string]$CollectionName

    )

    # Requires RDMgmt module (usually available on the Broker / admin hosts)

    Import-Module RemoteDesktop -ErrorAction Stop
 
    if ([string]::IsNullOrWhiteSpace($CollectionName)) {

        # Get all session hosts known to the deployment

        $allCollections = Get-RDSessionCollection -ConnectionBroker $Broker -ErrorAction Stop

        $hosts = foreach ($col in $allCollections) {

            Get-RDSessionHost -CollectionName $col.CollectionName -ConnectionBroker $Broker -ErrorAction Stop

        }

    } else {

        $hosts = Get-RDSessionHost -CollectionName $CollectionName -ConnectionBroker $Broker -ErrorAction Stop

    }
 
    $hosts | Select-Object -ExpandProperty SessionHost

}
 
function Convert-EventToHashtable {

    param([System.Diagnostics.Eventing.Reader.EventRecord]$Event)

    $xml = [xml]$Event.ToXml()

    $ht = @{}

    foreach ($d in $xml.Event.EventData.Data) {

        # Some Data elements may not have a Name; guard it

        $name = if ($d.Name) { $d.Name } else { "Data_$($ht.Count)" }

        $ht[$name] = $d.'#text'

    }

    return $ht

}
 
function Get-RdsLogonEventsForHost {

    param(

        [string]$ComputerName,

        [datetime]$StartTime,

        [datetime]$EndTime

    )
 
    # Security log: 4624 (success) & 4625 (failure), LogonType 10 (RDP)

    $fhSuccess = @{

        LogName    = 'Security'

        Id         = 4624

        StartTime  = $StartTime

        EndTime    = $EndTime

        ProviderName = 'Microsoft-Windows-Security-Auditing'

    }

    $fhFailure = @{

        LogName    = 'Security'

        Id         = 4625

        StartTime  = $StartTime

        EndTime    = $EndTime

        ProviderName = 'Microsoft-Windows-Security-Auditing'

    }
 
    $success = @()

    $failure = @()
 
    try {

        $success = Get-WinEvent -FilterHashtable $fhSuccess -ComputerName $ComputerName -ErrorAction Stop |

            Where-Object {

                # Filter LogonType == 10 (RemoteInteractive)

                $xml = [xml]$_.ToXml()

                $logonType = ($xml.Event.EventData.Data | Where-Object {$_.Name -eq 'LogonType'}).'#text'

                $logonType -eq '10'

            }

    } catch {

        Write-Warning "[$ComputerName] Failed to query 4624 events: $($_.Exception.Message)"

    }
 
    try {

        $failure = Get-WinEvent -FilterHashtable $fhFailure -ComputerName $ComputerName -ErrorAction Stop |

            Where-Object {

                $xml = [xml]$_.ToXml()

                $logonType = ($xml.Event.EventData.Data | Where-Object {$_.Name -eq 'LogonType'}).'#text'

                $logonType -eq '10'

            }

    } catch {

        Write-Warning "[$ComputerName] Failed to query 4625 events: $($_.Exception.Message)"

    }
 
    foreach ($e in $success) {

        $d = Convert-EventToHashtable -Event $e

        [PSCustomObject]@{

            TimeCreated            = $e.TimeCreated

            EventType              = 'Success'

            User                   = $d.TargetUserName

            Domain                 = $d.TargetDomainName

            SourceIP               = $d.IpAddress

            SourcePort             = $d.IpPort

            SessionHost            = $ComputerName

            LogonID                = $d.TargetLogonId

            LogonProcess           = $d.LogonProcessName

            AuthenticationPackage  = $d.AuthenticationPackageName

            WorkstationName        = $d.WorkstationName

            EventRecordId          = $e.RecordId

        }

    }
 
    foreach ($e in $failure) {

        $d = Convert-EventToHashtable -Event $e

        [PSCustomObject]@{

            TimeCreated            = $e.TimeCreated

            EventType              = 'Failure'

            User                   = $d.TargetUserName

            Domain                 = $d.TargetDomainName

            SourceIP               = $d.IpAddress

            SourcePort             = $d.IpPort

            SessionHost            = $ComputerName

            LogonID                = $d.TargetLogonId

            FailureReason          = $d.FailureReason

            SubStatus              = $d.SubStatus

            Status                 = $d.Status

            AuthenticationPackage  = $d.AuthenticationPackageName

            WorkstationName        = $d.WorkstationName

            EventRecordId          = $e.RecordId

        }

    }

}
 
# ----------------- MAIN -----------------

try {

    $hosts = Get-RDSessionHostsFromBroker -Broker $Broker -CollectionName $CollectionName

    if (-not $hosts -or $hosts.Count -eq 0) {

        throw "No RD Session Hosts found from Broker '$Broker'$(if($CollectionName){", collection '$CollectionName'."})"

    }

} catch {

    Write-Error $_.Exception.Message

    break

}
 
Write-Verbose "Querying time window: $StartTime -> $EndTime"

$results = foreach ($h in $hosts) {

    Get-RdsLogonEventsForHost -ComputerName $h -StartTime $StartTime -EndTime $EndTime

}
 
# Optional user filter

if ($UserLike) {

    $results = $results | Where-Object { $_.User -like "*$UserLike*" }

}
 
# Clean up machine accounts (e.g., 'SERVER$') if present

$results = $results | Where-Object { $_.User -and ($_.User -notlike '*$') }
 
# Sort for readability

$results = $results | Sort-Object TimeCreated, SessionHost
 
# Output

$results | Format-Table -AutoSize
 
if ($ExportCsvPath) {

    try {

        $results | Export-Csv -Path $ExportCsvPath -NoTypeInformation -Encoding UTF8

        Write-Host "Exported CSV to: $ExportCsvPath"

    } catch {

        Write-Warning "Failed to export CSV: $($_.Exception.Message)"

    }

}

 