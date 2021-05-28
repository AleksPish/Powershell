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