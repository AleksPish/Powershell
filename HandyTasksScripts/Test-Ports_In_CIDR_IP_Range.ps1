# PowerShell script to test connectivity to a range of IPs and ports and export results to CSV

$ports = @(3389, 22)
$ipRanges = @(
    "10.10.10.0/24",
    "192.168.1.0/24"
)

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

$allIPs = @()
foreach ($range in $ipRanges) {
    $allIPs += Get-IPsFromCIDR $range
}

$results = @()
foreach ($ip in $allIPs) {
    foreach ($port in $ports) {
        $result = Test-NetConnection -ComputerName $ip.IPAddressToString -Port $port -WarningAction SilentlyContinue
        $results += [PSCustomObject]@{
            IP   = $ip.IPAddressToString
            Port = $port
            TcpTestSucceeded = $result.TcpTestSucceeded
        }
    }
}

$results | Export-Csv -Path "C:\temp\TestNetConnectionResults.csv" -NoTypeInformation