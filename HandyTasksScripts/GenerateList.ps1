$prefix = "Name to generate"
$startNumber = 1
$endNumber = 10

for ($i = $startNumber; $i -le $endNumber; $i++) {
    $name = "{0}{1:D2}" -f $prefix, $i
    Write-Output $name
}