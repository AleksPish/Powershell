
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