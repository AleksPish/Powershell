[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param(
    [Parameter(Mandatory = $false)]
    [string]$ComputerName = $env:COMPUTERNAME
)

function Get-DisconnectedSessions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    $serverArg = if ($ComputerName -and $ComputerName -ne $env:COMPUTERNAME -and $ComputerName -ne "." -and $ComputerName -ne "localhost") {
        "/server:$ComputerName"
    }
    else {
        $null
    }

    $raw = if ($serverArg) { quser $serverArg 2>$null } else { quser 2>$null }

    if (-not $raw -or $raw.Count -lt 2) {
        return @()
    }

    $sessions = @()
    foreach ($line in $raw | Select-Object -Skip 1) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $clean = ($line -replace "^\s*>", "").Trim()
        $parts = $clean -split "\s{2,}"

        if ($parts.Count -lt 5) { continue }

        if ($parts.Count -ge 6) {
            $userName = $parts[0]
            $sessionName = $parts[1]
            $sessionId = $parts[2]
            $state = $parts[3]
            $idleTime = $parts[4]
            $logonTime = $parts[5]
        }
        else {
            $userName = $parts[0]
            $sessionName = ""
            $sessionId = $parts[1]
            $state = $parts[2]
            $idleTime = $parts[3]
            $logonTime = $parts[4]
        }

        if ($state -eq "Disc") {
            $sessions += [pscustomobject]@{
                ComputerName = $ComputerName
                UserName = $userName
                SessionName = $sessionName
                SessionId = [int]$sessionId
                State = $state
                IdleTime = $idleTime
                LogonTime = $logonTime
            }
        }
    }

    $sessions
}

$disconnectedSessions = Get-DisconnectedSessions -ComputerName $ComputerName

if (-not $disconnectedSessions -or $disconnectedSessions.Count -eq 0) {
    Write-Host ("No disconnected sessions found on {0}." -f $ComputerName) -ForegroundColor Yellow
    return
}

Write-Host ("Disconnected sessions found on {0}:" -f $ComputerName) -ForegroundColor Cyan
$disconnectedSessions | Select-Object UserName, SessionId, IdleTime, LogonTime | Format-Table -AutoSize

$results = @()
foreach ($session in $disconnectedSessions) {
    $target = "{0} (ID {1}) on {2}" -f $session.UserName, $session.SessionId, $session.ComputerName
    if ($PSCmdlet.ShouldProcess($target, "Log off disconnected session")) {
        try {
            if ($session.ComputerName -and $session.ComputerName -ne $env:COMPUTERNAME -and $session.ComputerName -ne "." -and $session.ComputerName -ne "localhost") {
                logoff $session.SessionId /server:$($session.ComputerName)
            }
            else {
                logoff $session.SessionId
            }

            $results += [pscustomobject]@{
                ComputerName = $session.ComputerName
                UserName = $session.UserName
                SessionId = $session.SessionId
                Status = "LoggedOff"
                Error = $null
            }
        }
        catch {
            $results += [pscustomobject]@{
                ComputerName = $session.ComputerName
                UserName = $session.UserName
                SessionId = $session.SessionId
                Status = "Failed"
                Error = $_.Exception.Message
            }
        }
    }
}

if ($results.Count -gt 0) {
    Write-Host ""
    Write-Host "Logoff results:" -ForegroundColor Cyan
    $results | Format-Table -AutoSize
}
