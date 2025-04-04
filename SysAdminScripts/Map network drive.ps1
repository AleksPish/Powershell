#Script to map a network  drive
$PWord = ConvertTo-SecureString -String "<Password>" -AsPlainText -Force
$User = "domain\username"

$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

New-PSDrive -Name "F" -Root "\\fileshare" -Persist -PSProvider "FileSystem" -Credential $cred
