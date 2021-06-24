function Get-Foldersizes {
    param (
        # Target folder
        [Parameter(Mandatory=$true)]
        [string]$TargetFolder, 
        # Output folder
        [Parameter(Mandatory=$true)]
        [string]$OutputFolder
    )

# Get the folders and sort  
$Folders = (Get-ChildItem $TargetFolder | Where-Object {$_.PSIsContainer -eq $True} | Sort-Object)

#Get info on each folder and input to PSobject
foreach ($i in $Folders)
    {
        $subFolderItems = (Get-ChildItem $i.FullName -recurse | Measure-Object -property length -sum)
        $size = '{0:N0}'-f ($subFolderItems.sum / 1MB)
            
            $output = New-Object PSObject -Property @{
            "Size MB" = $size
            Foldername = $i.Name
            }
        # Append info in PSobject to csv file on each loop
        $output  | Export-Csv $OutputFolder -Append -NoTypeInformation
        # Display output to console for quick viewing
        Write-host $i.FullName , $size
    }  
}



