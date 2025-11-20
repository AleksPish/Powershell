#Script to list all VMs included in Veeam Backup jobs along with their job names and vCenter information

# Load the Veeam PowerShell module (if not already loaded)
if (-not (Get-Module -Name Veeam.Backup.PowerShell -ErrorAction SilentlyContinue)) {
    try {
        Import-Module Veeam.Backup.PowerShell -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to load Veeam.Backup.PowerShell module. Ensure Veeam Backup & Replication is installed and the module is available."
        exit
    }
}

# Get all backup jobs
$backupJobs = Get-VBRJob | Where-Object { $_.JobType -eq "Backup" }

# Initialize an array to store VM details
$vmList = @()

# Loop through each backup job
foreach ($job in $backupJobs) {
    # Get the VMs in the job
    $jobObjects = Get-VBRJobObject -Job $job | Where-Object { $_.Type -eq "Include" -and $_.TypeDisplayname -eq "Virtual Machine" }
    
    # Extract VM details
    foreach ($obj in $jobObjects) {
        $vmList += [PSCustomObject]@{
            JobName   = $job.Name
            VMName    = $obj.Name
            ObjectId  = $obj.Object.Id
            vCenter   = $obj.Object.Host.Name
        }
    }
}

# Remove duplicates (in case a VM is included in multiple jobs)
$uniqueVMs = $vmList | Sort-Object VMName, JobName -Unique

# Display the results
$uniqueVMs | Format-Table -AutoSize

# Optionally, export to CSV
$uniqueVMs | Export-Csv -Path "C:\Temp\VeeamBackedUpVMs.csv" -NoTypeInformation