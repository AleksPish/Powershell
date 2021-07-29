###########################################################
function Get-MatchingString {
    param (
        # Target folder
        [Parameter(Mandatory=$true)]
        [string]$Path, 
        # Searching for
        [Parameter(Mandatory=$true)]
        [string]$Match,
        #Output location
        [Parameter(Mandatory=$true)]
        [string]$Output
        
    )

$PathArray = @()


# This gets all the files in $Path that conform to the search terms

Get-ChildItem $Path -Include "*.bat", "*.vbs", "*.cmd","*.txt" -Recurse | Where-Object { $_.Attributes -ne "Directory"} |

#Loops through objects for matches and puts matches into the patharray array
ForEach-Object {
    If (Get-Content $_.FullName | Select-String -Pattern $Match) {
    $PathArray += $_.FullName
    }
}
Write-Host "Contents of ArrayPath:"
$PathArray | ForEach-Object {$_}

#Can export using this:

$PathArray | ForEach-Object {$_} | Out-File $Output
}
##########################################################