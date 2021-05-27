function Get-Foldersizes {
    param (
        # Target folder
        [Parameter(Mandatory=$true)]
        [string]$TargetFolder, 
        # Output folder
        [Parameter(Mandatory=$true)]
        [string]$OutputFolder
    )

    
$colItems = (Get-ChildItem $TargetFolder | Where-Object {$_.PSIsContainer -eq $True} | Sort-Object)
$results = @()
$size = @()
foreach ($i in $colItems)
    {
        $i.FullName
        $subFolderItems = (Get-ChildItem $i.FullName -recurse | Measure-Object -property length -sum)
        $results +=  $i.Name  
        $size += ($subFolderItems.sum / 1MB)
    }
    $results,$size > $OutputFolder

}



