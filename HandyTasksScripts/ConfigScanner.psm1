<#
.SYNOPSIS
    PowerShell module for scanning configuration files to find IP addresses or hostnames.

.DESCRIPTION
    This module provides cmdlets to search through configuration files for specified IP addresses
    or hostnames, with support for single files or directories, and optional output to CSV.

.NOTES
    Author: Aleks Piszczynski
    Created: April 14, 2025
#>

# Helper function to validate IP address format
function Test-IPAddress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$IP
    )
    
    try {
        [System.Net.IPAddress]::Parse($IP) | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Helper function to process a single config file
function Search-ConfigFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Terms
    )
    
    Write-Verbose "Processing file: $FilePath"
    
    $results = @()
    $content = Get-Content -Path $FilePath -ErrorAction Stop
    $lineNumber = 0
    
    foreach ($line in $content) {
        $lineNumber++
        
        foreach ($term in $Terms) {
            $isIP = Test-IPAddress -IP $term
            
            if ($isIP) {
                if ($line -match "\b$([regex]::Escape($term))\b") {
                    $results += [PSCustomObject]@{
                        File      = $FilePath
                        Term      = $term
                        Type      = "IP"
                        Line      = $lineNumber
                        Content   = $line.Trim()
                    }
                }
            }
            else {
                if ($line -imatch "\b$([regex]::Escape($term))\b") {
                    $results += [PSCustomObject]@{
                        File      = $FilePath
                        Term      = $term
                        Type      = "Hostname"
                        Line      = $lineNumber
                        Content   = $line.Trim()
                    }
                }
            }
        }
    }
    
    return $results
}

<#
.SYNOPSIS
    Finds IP addresses or hostnames in configuration files.

.DESCRIPTION
    Scans one or more configuration files for specified IP addresses or hostnames.
    Returns objects with properties File, Term, Type, Line, and Content. Supports single file
    or directory scanning, with optional CSV output.

.PARAMETER SearchTerms
    Array of IP addresses or hostnames to search for.

.PARAMETER ConfigPath
    Path to a single config file or directory containing config files.

.PARAMETER OutputFile
    Optional path to save results to a CSV file.

.OUTPUTS
    PSCustomObject
    Returns objects with the following properties:
    - File: Path to the config file
    - Term: Matched IP or hostname
    - Type: 'IP' or 'Hostname'
    - Line: Line number where the match was found
    - Content: The full line content (trimmed)

.EXAMPLE
    $results = Find-ConfigMatch -SearchTerms "192.168.1.1","server1.local" -ConfigPath "C:\Configs"
    $results | Format-Table
    Stores results in $results and displays them as a table.

.EXAMPLE
    $results = Find-ConfigMatch -SearchTerms "10.0.0.1" -ConfigPath "C:\Configs\forti.conf"
    $results.Content
    Stores results and accesses the Content property.

.EXAMPLE
    Find-ConfigMatch -SearchTerms "192.168.1.1" -ConfigPath "C:\Configs" -OutputFile "C:\results.csv"
    Searches and exports results to a CSV file.

.NOTES
    The cmdlet returns raw objects for easy property access. Use Format-Table or other formatting cmdlets
    for display. Files must have a .conf extension when scanning directories.
#>
function Find-ConfigMatch {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$SearchTerms,
        
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath,
        
        [string]$OutputFile
    )
    
    begin {
        Write-Verbose "Starting config scan..."
    }
    
    process {
        try {
            # Validate ConfigPath
            if (-not (Test-Path -Path $ConfigPath)) {
                throw "Path not found: $ConfigPath"
            }

            $allResults = @()
            $filesToProcess = @()

            # Determine if ConfigPath is a file or directory
            if (Test-Path -Path $ConfigPath -PathType Leaf) {
                $filesToProcess = @($ConfigPath)
            }
            else {
                $filesToProcess = Get-ChildItem -Path $ConfigPath -Filter "*.conf" -Recurse -File -ErrorAction Stop | 
                    Select-Object -ExpandProperty FullName
            }

            if ($filesToProcess.Count -eq 0) {
                throw "No .conf files found in the specified path."
            }

            # Process each file
            foreach ($file in $filesToProcess) {
                $fileResults = Search-ConfigFile -FilePath $file -Terms $SearchTerms
                $allResults += $fileResults
            }

            # Return results
            if ($allResults.Count -eq 0) {
                Write-Warning "No matches found for the specified terms."
            }
            else {
                # Output the raw objects to the pipeline
                $allResults
                
                # Export to CSV if OutputFile is specified
                if ($OutputFile) {
                    $allResults | Export-Csv -Path $OutputFile -NoTypeInformation -ErrorAction Stop
                    Write-Verbose "Results exported to: $OutputFile"
                }
            }
        }
        catch {
            Write-Error "An error occurred: $_"
        }
    }
    
    end {
        Write-Verbose "config scan completed."
    }
}

# Export the public cmdlet
Export-ModuleMember -Function Find-ConfigMatch