#New local admin account

$pw = convertto-securestring -string "password" -AsPlainText -force;
$name = "Name"

new-localuser -name $name -password $pw;

Add-localgroupmember -group Administrators -Member $name;