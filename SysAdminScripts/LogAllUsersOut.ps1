$users = (quser)
$userlist = [System.Collections.Generic.List[System.Object]]($users)
$userlist.removeat(0)
foreach($user in $userlist){
$id = $user.substring(42,2)
    invoke-expression -command "logoff $id"
}