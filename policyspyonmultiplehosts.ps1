#Use this code snippet for Multiple PC's

"$(Get-Date -DisplayHint DateTime) ; start of script" | Tee-Object $env:USERPROFILE\desktop\policyspy.log -Append
$computers = gc c:\computers.txt
foreach($computer in $computers)
{
"$(Get-Date -DisplayHint DateTime) ; checking for $computer" | Tee-Object $env:USERPROFILE\desktop\policyspy.log -Append
$policytimestamp = (gwmi -ComputerName $computer -Namespace "root\ccm\policyagent" -Query "select * from CCM_ActualConfigUpdateInfo where namespacesid = 'S-1-5-18'").UpdatedTime
$converteddatetime = [DateTime]::FromFileTime($policytimestamp)
$difference = (New-TimeSpan -Start $converteddatetime -End $(Get-Date -DisplayHint DateTime)).Days
"$(Get-Date -DisplayHint DateTime) ; Last machine policy sync on $computer was on $converteddatetime" | Tee-Object $env:USERPROFILE\desktop\policyspy.log -Append
if ($difference -gt 2)
{
Invoke-WMIMethod -ComputerName $computer -Namespace root\ccm -Class SMS_Client -Name ResetPolicy -ArgumentList "1" -Verbose
"$(Get-Date -DisplayHint DateTime) ; Resetting machine policy on $computer since policy sync was out of threshold" | Tee-Object $env:USERPROFILE\desktop\policyspy.log -Append
}
else
{
"$(Get-Date -DisplayHint DateTime) ; No action performed on $computer" | Tee-Object $env:USERPROFILE\desktop\policyspy.log -Append
}
}
"$(Get-Date -DisplayHint DateTime) ; end of script" | Tee-Object $env:USERPROFILE\desktop\policyspy.log -Append
