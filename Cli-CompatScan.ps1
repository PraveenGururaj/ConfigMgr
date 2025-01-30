#script to check OS Upgrade compatibility
New-PSDrive -Name "W" -PSProvider FileSystem -Root "\\VM0\ISO" -Persist -Scope Global | Out-Null
Set-Location "W:"
#Invoke Disk CleanUp for cleaning up old upgrade files
$DiskCleanUp = Start-Process "$env:WINDIR\SYSTEM32\CleanMgr.exe" -ArgumentList "/AUTOCLEAN" -Wait -NoNewWindow -PassThru
$CompatCheck = Start-Process "W:\setup.exe" -ArgumentList "/auto upgrade /quiet /compat scanonly /compat ignorewarning /copylogs C:\TMP\WUCompat-$($env:COMPUTERNAME)" -Wait -NoNewWindow -PassThru
$Dec2Hex = $CompatCheck.ExitCode.ToString("X")
$CompatRes = switch($Dec2Hex)
    {
        "C1900210" {"COMPATIBLE"}
        "C1900208" {"SWBLOCK"}
        "C1900204" {"INVBLOCK"}
        "C1900200" {"HWBLOCK"}
        "C190020E" {"DSKSPC"}
    }
[xml]$ScanResult = Get-Content "C:\TMP\WUCompat-$($env:COMPUTERNAME)\Panther\ScanResult.xml"
#Script Block for identifying HW Blocks
$HWBlock = [System.Collections.Generic.List[string]]::new()
$HWItems = $ScanResult.CompatReport.Hardware.HardwareItem
    foreach($HWItem in $HWItems)
        {
            if ($HWItem.CompatibilityInfo.BlockingType -ne "None")
            {
                $HWBlock.Add($HWItem.HardwareType)
            }
        }
$HWBlockINF = $HWBlock -join ","
#End of HW Block identification
#Script Block for identifying Driver blocks
$DrvItems = $ScanResult.CompatReport.DriverPackages.DriverPackage
$DrvBlock = [System.Collections.Generic.List[string]]::new()
foreach($DrvItem in $DrvItems)
    {
        if($DrvItem.BlockMigration -eq $true)
        {
            $DrvBlock.Add($DrvItem.Inf)
        }
    }
$DrvBlockINFs = $DrvBlock -join ","
#End of Drv Block Identification
New-Item -Name PSAutomation -Path HKLM:\SOFTWARE -Force | Out-Null
New-Item -Name CompatScan -Path HKLM:\SOFTWARE\PSAutomation -Force | Out-Null
New-ItemProperty -Name CompatRes -Path HKLM:\SOFTWARE\PSAutomation\CompatScan -PropertyType String -Value $CompatRes -Force | Out-Null
New-ItemProperty -Name HWBlockINF -Path HKLM:\SOFTWARE\PSAutomation\CompatScan -PropertyType String -Value $HWBlockINF -Force | Out-Null
New-ItemProperty -Name DrvBlockINF -Path HKLM:\SOFTWARE\PSAutomation\CompatScan -PropertyType String -Value $DrvBlockINFs -Force | Out-Null
#Remove Print to PDF and XPS Viewer feature is found to be the blocking driver
$WinDrvs = Get-WindowsDriver -Online
$PrintDrvs = Get-PrinterDriver
foreach($DrvBlockINF in $DrvBlockINFs.Split(","))
    {
    foreach($WinDrv in $WinDrvs)
        {
        foreach($PrintDrv in $PrintDrvs)
            {
            if (($DrvBlockINF -eq $WinDrv.Driver) -and ($WinDrv.OriginalFileName -eq $PrintDrv.InfPath) -and ($WinDrv.ClassName -like "Printer") -and ($PrintDrv.Name -like "*XPS*"))
                {
                Remove-WindowsCapability -Name "XPS.Viewer~~~~0.0.1.0" -Online -ea SilentlyContinue
                Remove-WindowsDriver -Driver $WinDrv.Driver -ea SilentlyContinue
                Remove-PrinterDriver -Name $PrintDrv.Name -RemoveFromDriverStore -ea SilentlyContinue
                Remove-Printer -Name "*XPS*" -ea SilentlyContinue
                }
            elseif (($DrvBlockINF -eq $WinDrv.Driver) -and ($WinDrv.OriginalFileName -eq $PrintDrv.InfPath) -and ($WinDrv.ClassName -like "Printer") -and ($PrintDrv.Name -like "*Microsoft Print To PDF*"))
                {
                Disable-WindowsOptionalFeature -FeatureName "Printing-PrintToPDFServices-Features" -Online -Remove -NoRestart -ea SilentlyContinue
                Remove-WindowsDriver -Driver $WinDrv.Driver -ea SilentlyContinue
                Remove-PrinterDriver -Name $PrintDrv.Name -RemoveFromDriverStore -ea SilentlyContinue
                Remove-Printer -Name "*PDF*" -ea SilentlyContinue
                }
            }
        }
    }

$DiskCleanUp = Start-Process "$env:WINDIR\SYSTEM32\CleanMgr.exe" -ArgumentList "/AUTOCLEAN" -Wait -NoNewWindow -PassThru
Remove-PSDrive -Name W -Force
exit 0