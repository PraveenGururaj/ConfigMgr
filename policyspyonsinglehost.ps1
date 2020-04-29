#Use this code snippet for Single PC

$policytimestamp = (gwmi -Namespace "root\ccm\policyagent" -Query "select * from CCM_ActualConfigUpdateInfo where namespacesid = 'S-1-5-18'").UpdatedTime
$converteddatetime = [DateTime]::FromFileTime($policytimestamp)
$difference = (New-TimeSpan -Start $converteddatetime -End $(Get-Date -DisplayHint DateTime)).Days
if ($difference -gt 2)
{
Invoke-WMIMethod -Namespace root\ccm -Class SMS_Client -Name ResetPolicy -ArgumentList “1” -Verbose
}
