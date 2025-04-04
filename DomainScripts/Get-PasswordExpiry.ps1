function Get-PasswordExpiry {
    param (
        $user
    )
    Get-ADUser -Identity $user -Properties DisplayName, msDS-UserPasswordExpiryTimeComputed | Select-Object -Property Displayname,@{Name="Expiration Date";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
}

function Get-PasswordExpiryAllUsers {

    Get-ADUser -Identity -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} -Properties DisplayName, msDS-UserPasswordExpiryTimeComputed | Select-Object -Property Displayname,@{Name="Expiration Date";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}

}