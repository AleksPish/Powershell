function Get-CPUTemp {
    (((Get-CimInstance MSAcpi_ThermalZoneTemperature -Namespace "root/wmi").CurrentTemperature / 10) -273)
}

