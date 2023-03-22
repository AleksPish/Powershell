function Enter-Task {
    param (
        $entry
    )
    $date = (get-date).ToLongDateString()
    $fileCheck = test-path "C:\Tasks\$date.txt"
    $file = "C:\Tasks\$date.txt"
    if ($false -eq $fileCheck){
        New-Item -ItemType "File" -Path "C:\Tasks\$date.txt"
    }
    $timestamp = (Get-date).TimeOfDay

    $output = $entry

    $output += "    $timestamp"
    $output | Out-file  -Append -Path $file
}