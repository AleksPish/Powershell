#Get errors from powershell and output
#Start by clearing the error variable 
$Error.Clear()

#Execute Get-ChildItem with -ErrorAction Continue

Get-ChildItem -Recurse $targetdir -ErrorAction Continue `
    | Where-Object { $_.Name -EQ $name } `
    | ForEach-Object {
        echo-indented "Found $(hash $_) at $($_.FullName)"
        $_
    }

#Display objects we got Access Denies on:
$Error | ForEach-Object {
    Write-Host $_.TargetObject
}