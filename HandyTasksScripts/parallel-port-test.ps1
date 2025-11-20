# PowerShell script to test connectivity to a range of IPs and ports in parallel and export results to CSV

$ports = @(3389, 22)
$ipRanges = @("10.10.10.0/24")

function Get-IPsFromCIDR($cidr) {
    $ip, $mask = $cidr -split '/'
    $ipBytes = [System.Net.IPAddress]::Parse($ip).GetAddressBytes()
    [Array]::Reverse($ipBytes)
    $ipInt = [BitConverter]::ToUInt32($ipBytes, 0)
    $maskInt = [uint32]([math]::Pow(2,32) - 1) -bxor ([uint32]([math]::Pow(2, (32 - [int]$mask)) - 1))
    $network = $ipInt -band $maskInt
    $broadcast = $network + [uint32]([math]::Pow(2, (32 - [int]$mask)) - 1)
    $ips = @()
    for ($i = $network + 1; $i -lt $broadcast; $i++) {
        $bytes = [BitConverter]::GetBytes($i)
        [Array]::Reverse($bytes)
        $ips += [System.Net.IPAddress]::new($bytes)
    }
    return $ips
}

# Get all IPs from the ranges
$allIPs = @()
foreach ($range in $ipRanges) {
    $allIPs += Get-IPsFromCIDR $range
}

Write-Host "Testing connectivity to $($allIPs.Count) IPs across $($ports.Count) ports..."
Write-Host "Total tests: $($allIPs.Count * $ports.Count)"

# Create runspace pool for faster parallel execution
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 50)
$runspacePool.Open()

$runspaces = [System.Collections.Generic.List[PSObject]]::new()
$results = [System.Collections.Generic.List[PSObject]]::new()

# Script block for testing a single IP-port combination (optimized)
$testScript = {
    param($ip, $port, $timeout = 1000)  # Reduced timeout to 1 second
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($ip, $port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne($timeout, $false)
        
        if ($wait) {
            try {
                $tcpClient.EndConnect($connect)
                $status = "Open"
            }
            catch {
                $status = "Closed"
            }
        }
        else {
            $status = "Timeout"
        }
        
        $tcpClient.Close()
    }
    catch {
        $status = "Error"
    }
    
    return @{
        IP = $ip.ToString()
        Port = $port
        Status = $status
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Start all tests using runspaces (much faster than jobs)
foreach ($ip in $allIPs) {
    foreach ($port in $ports) {
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $runspacePool
        $powershell.AddScript($testScript).AddArgument($ip).AddArgument($port) | Out-Null
        
        $runspaces.Add((@{
            PowerShell = $powershell
            Handle = $powershell.BeginInvoke()
            IP = $ip.ToString()
            Port = $port
        }))
    }
}

Write-Host "Started $($runspaces.Count) parallel tests using runspaces..."

# Process completed runspaces
$completedTests = 0
while ($runspaces.Count -gt 0) {
    $completedRunspaces = $runspaces | Where-Object { $_.Handle.IsCompleted }
    
    foreach ($runspace in $completedRunspaces) {
        try {
            $result = $runspace.PowerShell.EndInvoke($runspace.Handle)
            if ($result -and $result.Count -gt 0) {
                # Get the first (and only) result from the runspace
                $resultData = $result[0]
                $resultObject = [PSCustomObject]@{
                    IP = $resultData.IP
                    Port = $resultData.Port
                    Status = $resultData.Status
                    Timestamp = $resultData.Timestamp
                }
                $results.Add($resultObject)
                
                # Display result immediately
                $status = $resultObject.Status
                $statusColor = switch ($status) {
                    "Open" { "Green" }
                    "Closed" { "Red" }
                    "Timeout" { "Yellow" }
                    "Error" { "Magenta" }
                    default { "White" }
                }
                
                Write-Host "[$($resultObject.Timestamp)] " -NoNewline -ForegroundColor Gray
                Write-Host "$($resultObject.IP):$($resultObject.Port) " -NoNewline
                Write-Host "$status" -ForegroundColor $statusColor
            }
        }
        catch {
            Write-Warning "Runspace failed for $($runspace.IP):$($runspace.Port) - $($_.Exception.Message)"
        }
        
        $runspace.PowerShell.Dispose()
        $completedTests++
        
        # Show progress every 100 completed tests
        if ($completedTests % 100 -eq 0) {
            $remaining = $runspaces.Count - $completedRunspaces.Count
            Write-Host "`n--- Progress: $completedTests / $($runspaces.Count) tests completed ($remaining remaining) ---" -ForegroundColor Cyan
        }
    }
    
    # Remove completed runspaces
    $runspaces = $runspaces | Where-Object { -not $_.Handle.IsCompleted }
    Start-Sleep -Milliseconds 50  # Shorter sleep for faster processing
}

# Clean up
$runspacePool.Close()
$runspacePool.Dispose()

Write-Host "All tests completed! Processing results..."

# Export results to CSV
$outputFile = "port-connectivity-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$results | Sort-Object IP, Port | Export-Csv -Path $outputFile -NoTypeInformation

Write-Host "Results exported to: $outputFile"
Write-Host "Total results: $($results.Count)"

# Display summary
$openPorts = ($results | Where-Object { $_.Status -eq "Open" }).Count
$closedPorts = ($results | Where-Object { $_.Status -eq "Closed" }).Count
$timeouts = ($results | Where-Object { $_.Status -eq "Timeout" }).Count

Write-Host "`nSummary:"
Write-Host "Open ports: $openPorts"
Write-Host "Closed ports: $closedPorts"
Write-Host "Timeouts: $timeouts"

# Show open ports if any
if ($openPorts -gt 0) {
    Write-Host "`nOpen ports found:"
    $results | Where-Object { $_.Status -eq "Open" } | Sort-Object IP, Port | Format-Table -AutoSize
}