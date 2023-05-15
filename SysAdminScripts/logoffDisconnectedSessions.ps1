$users = (quser | Where-Object {$_ -match 'Disc'})

if($null -ne $users){

    foreach($user in $users){
    $id = $user.substring(42,2)
    invoke-expression -command "logoff $id"
    }
}
else {Write-host "no dissconected sessions"}