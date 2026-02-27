# Function to add to $profile if you are too lazy to type mstsc -v 

function Connect-RDP {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias('ComputerName', 'Host', 'Server', 'Target')]
        [string[]]$Hostname
    )

    process {
        foreach ($h in $Hostname) {
            Write-Verbose "Launching RDP to: $h"
            Start-Process mstsc.exe -ArgumentList "/v:$h"
        }
    }
}

# Create short alias 'rdp'
Set-Alias -Name rdp -Value Connect-RDP -Force -Option AllScope -Description "Quick RDP connection launcher"

# Optional: alias 'rdc' too (common alternative)
Set-Alias -Name rdc -Value Connect-RDP -Force -Option AllScope