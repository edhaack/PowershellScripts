<#
PURPOSE: Copy Attachment Images, Thumbs and Reports to FTP.

First of two parts that syncs attachment uploads from production to the Test Environment.

Second part: 
 1. FTP all files in 'CDX-Attachments' directory
 2. Copy to XDWEBTEST P:\ApplicationImages_Prod\Attachments
 3. Remove from FTP
#>
$startTime = Get-Date
$isReady = $true
cls
"
Script Start-Time: $startTime
"

#Set variables & constants
$numberOfDaysAgo = 25
$WABACdate = (Get-Date).AddDays(-$numberOfDaysAgo).ToString("d")

$sourcePath = "P:\ApplicationImages_Prod\Attachments"
$targetPath = "\\ftp\FTP2\Xceligent\Departments\IT\CDX-Attachments"

# BEGIN SCRIPT FUNCTION ===========================================

#Copy attachments from source to FTP location...
"Copying new files since: $WABACdate"

#Test Source Path
if(!(Test-Path $sourcePath)){ 
	write-host "Missing Source Path: $sourcePath" -ForegroundColor DarkRed
	$isReady = $false
}

#Test Target Path
if(!(Test-Path $targetPath)){ 
	write-host "Missing Target Path: $targetPath" -ForegroundColor DarkRed
	$isReady = $false
}

if($isReady){

	#NOTE: the "\*" on target prevents prompting for "d"irectory or "f"ile
	cmd.exe /c xcopy $sourcePath $targetPath\* /D:$WABACdate /S

}

# END SCRIPT FUNCTION ===========================================

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
 
"
Complete at: $endTime
 
Duration:
{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours
 
# Script Execution - BEGIN
