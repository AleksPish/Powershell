
try {
$files = Get-ChildItem "<filepath>" -Recurse -ErrorAction Inquire
}
Catch {
$errors = "$($_.TargetObject)"
 $errors | Out-file -filepath C:\temp\folderdenies.txt -Append
}
$Error | ForEach-Object {
    $path =  $_.TargetObject
    $path | out-file <outputfile> -append
}