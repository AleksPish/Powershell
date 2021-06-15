function Get-SimpleFoldersizes {
    
# Get the folders and sort  
$Folders = (Get-ChildItem | Where-Object {$_.PSIsContainer -eq $True} | Sort-Object)

#Get info on each folder and input to PSobject
foreach ($i in $Folders)
    {
        $subFolderItems = (Get-ChildItem $i.FullName -recurse | Measure-Object -property length -sum)
        $size = ($subFolderItems.sum / 1MB)
         
        Write-host $i.Name , $size
    }  
}