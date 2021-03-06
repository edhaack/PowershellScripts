<#
PURPOSE: Copy Attachment Images, Thumbs and Reports to FTP.

This script should reside on Production STATE1, and be executed as a Scheduled Task, daily.

CREATED: 2014.05.23 - ESH
UPDATED: 2014.05.30 - ESH Added creation of list file so that 2nd part can download it to use for what to dl.


First of two parts that copies attachment uploads from Production to the Test Environment.

Second part: 
 1. Download: ListFile.txt (contains full path to files)
 2. For each file in the list, 
 		Replace "\\ftp\FTP2\Xceligent\Departments\IT\CDX-Attachments" w/ ""
		FTP all files in 'CDX-Attachments' directory
		Copy to XDWEBTEST P:\ApplicationImages_Prod\Attachments
 3. Remove all from FTP

#>
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

$startTime = Get-Date

$timeDateStamp = $(Get-Date -f yyyy-MM-dd)
$logFile = "AttachmentDeltas-$timeDateStamp.log"


$isReady = $true
cls
Start-Transcript -path $logFile -append

"
Script Start-Time: $startTime
"

#Set variables & constants
$numberOfDaysAgo = 1
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
	cmd.exe /c xcopy $sourcePath $targetPath\* /D:$WABACdate /S /Y
	
	#Generate ListFile.txt for FTP to not have to list the files
	gci $targetPath\* -recurse -force | Select-Object -exp FullName | Out-File $targetPath\FileList.txt

}

# END SCRIPT FUNCTION ===========================================

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
 
"
Complete at: $endTime
 
Duration:
{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours
 
# Script Execution - BEGIN

Stop-Transcript
