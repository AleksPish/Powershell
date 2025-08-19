#Commands For AD Connect / AD Sync Info

#Show version of AD Connect
(Get-ADSyncGlobalSettings).parameters['Microsoft.Synchronize.ServerConfigurationVersion']

#Check AD Connect Upgrade setting
Get-ADSyncAutoUpgrade