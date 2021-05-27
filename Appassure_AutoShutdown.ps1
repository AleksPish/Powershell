#Creates a function that finds the host name and determines wether the replication is incomeing or outgoing. It then inturn suspends or starts replication depending if the function action is start or stop.

function Replication ($action)
{
	#serches for incomeing trafic and pauses/starts replication
	
	#write-host "1st loop"
	
	$Files = @(get-childitem "hklm:\SOFTWARE\AppRecovery\Core\Replication\RemoteCores\Masters")
    write-host "Masters:" $Files.length
	if ($Files.length -gt 0) 
		{
			get-childitem "hklm:\SOFTWARE\AppRecovery\Core\Replication\RemoteCores\Masters" | select pschildname | Foreach-Object {
			$key="hklm:\SOFTWARE\AppRecovery\Core\Replication\RemoteCores\Masters\"+$_.pschildname
			$hostname=get-itemproperty $key -name hostname | select -ExpandProperty HostName
			write-host $hostname
            
		if ($action -eq "stop")
				{
				suspend-replication -incoming $hostname -a
				}
		else
				{
				resume-replication -incoming $hostname -a
				}	
			}
		}	

	#serches for outgoing traffic and pauses/starts replication

	write-host "2nd loop"	
	
	$Files = ""	

	$Files = @(get-childitem "hklm:\SOFTWARE\AppRecovery\Core\Replication\RemoteCores\Slaves")
	write-host "Slaves:" $Files.length
	if ($Files.length -gt 0) 
 
		{
			get-childitem "hklm:\SOFTWARE\AppRecovery\Core\Replication\RemoteCores\Slaves" | select pschildname | Foreach-Object {
			$key="hklm:\SOFTWARE\AppRecovery\Core\Replication\RemoteCores\Slaves\"+$_.pschildname
			$hostname=get-itemproperty $key -name hostname | select -ExpandProperty HostName
			write-host $hostname
  
		if ($action -eq "stop")
				{
				suspend-replication -outgoing $hostname -a
				}
		else
				{
				resume-replication -outgoing $hostname -a
				}
			}
		}
}		
		
# Pause all snapshots exports and replication (replication uses the previously created function)

suspend-vmexport -a

suspend-snapshot -a

write-host "stop"

Replication "stop"

 <# 
.Synopsis 
 Cancel queued jobs
.Description
 Queued jobs may be canceled using this script. The script runs either on a one time basis or in an infinite loop. If this is the case it may be stopped by hitting ctrl-c
.Parameter donotstop
 enables the infinite loop
.Example 
.\cancelqueuedjobs
.Example
.\cancelqueuedjobs -donotstop
#>
 param([switch]$donotstop)
 cls
 $starttime = get-date
 $duration=$null
 $i=$null
 for(;;){
 $ajobs = get-activejobs -all | where {$_.status -eq "Queued"}
 $x=$ajobs.count
 if($x -le 0){$x = $null}
 if($i){$duration = "(running for $((New-TimeSpan -start $starttime -end (get-date)).ToString().substring(0,11)))"}
 Write-Host "`nCancelling $x Queued Jobs Loop $i $duration" -ForegroundColor Green
 $i++
 foreach ($ajob in $ajobs){
 $protectedserver = $ajob.summary
 $jobid = $ajob.Id
 Write-Host "Cancelling queued job: $protectedserver" -f Yellow
 Invoke-RestMethod -Uri "https://$($env:computername):8006/apprecovery/api/core/jobmgr/jobs/$jobId" -Method DELETE -UseDefaultCredentials
 }
 if(!($donotstop)){
 break
 }
 start-sleep 180
 }

set-service appassurecore -startuptype disabled

# Starts loop which will resume snapshots in 4 hours if jobs do not finish.

$starttime = get-date
$endtime = $starttime.addhours(4)
do 
{ 

    $currenttime = get-date

# This starts everything back up if the loop is over 4 hours.	
	
If ($currenttime -ge $endtime ) 
		{

		Resume-vmexport -a

		resume-snapshot -a 

write-host "restart"

		replication ("start")

		set-service appassurecore -startuptype automatic

		exit
		}

# This gets the active jobs when the loop is under 4 hours.

else 
		{
		$activejobs = get-activejobs -a 
		}
}

until ($activejobs -eq $null) 

# When jobs are finished service is stoped.

Stop-service appassurecore

# Clears mongo db logs.

cd "c:\program files\apprecovery\core\coreservice\mongodb" 

.\mongod.exe --repair --dbpath C:\programdata\apprecovery\eventsdatabase\appassure

Restart-computer -force

