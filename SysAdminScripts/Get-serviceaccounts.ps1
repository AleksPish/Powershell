#Get all accounts used for services.

$services = (get-service).Name

foreach($service in $services){
write-host $service 
(Get-WmiObject Win32_Service -Filter "Name='$service'").StartName
write-host "----------"
}

