function Delete-Profile {
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [string[]]$Exclude
    )
    $Exclude | Sort-Object | ForEach-Object{ Add-Log -Path $logPath -Message ("Excluding:  {0}" -f $_) }
    $profiles = Get-WMIObject -Class Win32_UserProfile
    Add-Log -Path $logPath -Message ("Found {0} profiles..." -f $profiles.Count)
    foreach ( $profile in $profiles ) {
        $Loaded = $false
        $Excluded = $false
        Add-Log -Path $logPath -Message ("Processing profile {0}..." -f $profile.LocalPath)
        if ( $profile.Loaded ) {
            Add-Log -Path $logPath -Message ("{0} profile is loaded. Deletion will be skipped." -f $profile.LocalPath)
            $Loaded = $true
        }
        
        if ( $Exclude -contains $profile.LocalPath.Substring($profile.LocalPath.lastindexofany("\") + 1, $profile.LocalPath.Length - ($profile.LocalPath.lastindexofany("\") + 1)) ) {
            Add-Log -Path $logPath -Message ("{0} profile has been excluded. Deletion will be skipped." -f $profile.LocalPath)
            $Excluded = $true
        }
        
        If ($Loaded -eq $false -And $Excluded -eq $false) {
            Add-Log -Path $logPath -Message ("Attempting to delete {0} profile..." -f $profile.LocalPath)
            try {
                if ($pscmdlet.ShouldProcess($profile.LocalPath, "Delete")) {
                    $profile.delete()
                    Add-Log -Path $logPath -Message ("{0} profile has been deleted successfully." -f $profile.LocalPath)
                }
                
            }
            catch {
                Add-Log -Path $logPath -Message ("{0} profile could not be deleted. Error: {1}" -f $profile.LocalPath, $_.Exception.Message) -Level Error
            }
        }
    }
}
$scriptPath = split-path -parent 
$MyInvocation.MyCommand.Definition
$logName = $MyInvocation.MyCommand.Name.ToLower().Replace("ps1","log")
$logPath = "{0}\{1}" -f $scriptPath, $logName

Add-Log -Path $logPath -Message ("Initiating {0}..." -f $MyInvocation.MyCommand)
Write-Verbose ("Logging Path: {0}" -f $logPath)
Add-Log -Path $logPath -Message ("Loading static exclusions...")
$exclusions = "Administrator","all users","default user","default", "localservice","networkservice","public","myserviceaccount"


Add-Log -Path $logPath -Message ("Beginning profile removal...")
Delete-Profile -Exclude $exclusions @PSBoundParameters
Add-Log -Path $logPath -Message ("Completed profile removal.  Script execution complete.")