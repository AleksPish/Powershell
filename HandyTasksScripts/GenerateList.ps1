$prefix = "6.0.0."
$startNumber = 1
$endNumber = 254

for ($i = $startNumber; $i -le $endNumber; $i++) {
    $name = "{0}{1:D2}" -f $prefix, $i
    Write-Output $name
}