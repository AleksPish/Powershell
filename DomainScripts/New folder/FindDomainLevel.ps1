#######################################
#/-----------------------------------\#
#|Aleks Piszczynski - piszczynski.com|#
#\-----------------------------------/#
#######################################
<#
.Synopsis
   Find the Domain Functional Level of the domain
#>

function FindDomainLevel {
   

$dse = ([ADSI] "LDAP://RootDSE")

Write-host "Domain controller Level"
$dse.domainControllerFunctionality
Write-host "Domain functional Level"
# Domain Functional Level
$dse.domainFunctionality
Write-host "Forest functional Level"
# Forest Functional Level
$dse.forestFunctionality


Write-Host

"************************************************************
Value  Forest        Domain             Domain Controller
0      2000          2000 Mixed/Native  2000
1      2003 Interim  2003 Interim       N/A
2      2003          2003               2003
3      2008          2008               2008
4      2008 R2       2008 R2            2008 R2
5      2012          2012               2012
6      2012 R2       2012 R2            2012 R2
7      2016          2016               2016"
}

FindDomainLevel