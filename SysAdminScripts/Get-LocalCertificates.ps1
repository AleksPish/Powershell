$certs = Get-ChildItem -Path cert:\* -Recurse | Where-Object {$_.Subject -like '<certificate Name>'}