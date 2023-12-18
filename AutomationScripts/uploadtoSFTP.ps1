#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
  Use WinSCP to upload files and download files from SFTP server
.DESCRIPTION
   Use WinSCP to upload files and download files from SFTP server - files downloaded will need to be older than 1 minute
#>


#Create Function for conformation + error Emails:
$errorEmailAddress = @("emailname <email address>")
$senderEmailAddress = "emailname <email address>"
$log = ""

Function Add-LogLine ($line)
{
    $timestamp = Get-date -Format "yyyy-M-dd HH:mm:ss"
    $script:log += "[$timestamp] $line`n"
}

function Send-ErrorEmail {
    param (
    $email,
    [String]$errormessage,
    [string]$logs
    )

    $template = @"
<contents for email>
 $errormessage

Logs:
$logs
"@
    $body = $template
    Send-MailMessage -From $senderEmailAddress -To $email -Body $body -SmtpServer <email server hostname/FQDN> -Credential <credentials> -Subject "<subject>"
}


# SFTP server details
$sftpHost = "<hostname>"
$sftpPort = 22
$sftpUsername = "<username>"
$sftpPassword = "<password>"



# Define the path to the WinSCP .NET assembly DLL
$winscpPath = "C:\Automation\WinSCP-6.1.2-Automation\WinSCPnet.dll" # Update this path as needed

# Load the WinSCP .NET assembly
Add-Type -Path $winscpPath

try {
    # Create a SessionOptions object with SFTP settings
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = $sftpHost
        PortNumber = $sftpPort
        UserName = $sftpUsername
        Password = $sftpPassword 
        SshHostKeyFingerprint = "<ssh fingerprint of sftp server>"
    }


    # Remote directory path
$remotePath = "<remote path on sftp server>"

# Local directory path to save downloaded files
$localPath = "<local path to save files to>"

#Path to files to upload
$uploadPath = "<path to upload files from>"

#Destination for uploaded files
$uploadDestination = "<file path for uploaded files on sftp server>"

    # Initialize the session
    $session = New-Object WinSCP.Session

    try {
        # Connect to the SFTP server
        $session.Open($sessionOptions)
        Add-LogLine -line "Connect to SFTP Server"
        # Perform SFTP operations
        $remoteFiles = $session.EnumerateRemoteFiles($remotePath, $null, [WinSCP.EnumerationOptions]::AllDirectories)
        foreach ($file in $remoteFiles){
            write-host "$($file.FullName) $($file.LastWritetime)"
            $olderthan = ((Get-Date).addminutes(-1))
            if($($file.LastWriteTime) -lt $olderthan){
            $transferOptions = New-Object WinSCP.TransferOptions
            $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
            $session.GetFiles($($file.FullName), "$localPath\$($file.name)", $true, $transferOptions)
            }
            else{
                write-host "$file is younger than 1 minute"
            }
            
        }
        
        
        $transferOptions = New-Object WinSCP.TransferOptions
        $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
        $session.PutFiles("$uploadpath\*", "$uploadDestination/", $true, $transferOptions)
        
    }
    catch {
        $errormessage = "Error: $($_.Exception.Message)"
        write-host $errormessage
            foreach($recepient in $errorEmailAddress){
            Send-ErrorEmail -email $recepient -errormessage $errormessage -logs $log
            }
        }
}
finally {
    if ($null -ne $session) {
        # Disconnect and release resources if not already done
        $session.Dispose()
    }
}
