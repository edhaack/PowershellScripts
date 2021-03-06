<#
PURPOSE: Copy Attachment Images, Thumbs and Reports
#>
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd-HH-mm)
$logFile = "AttachmentCopy-$timeDateStamp.log"

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
$targetPath = "V:\ApplicationImages_Prod\Attachments"

# BEGIN SCRIPT FUNCTION ===========================================

#Copy attachments from source to FTP location...
#"Copying new files since: $WABACdate"

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

function DoCopy($dir) {
	#NOTE: the "\*" on target prevents prompting for "d"irectory or "f"ile
	"$sourcePath\$dir"
	cmd.exe /c xcopy $sourcePath\$dir $targetPath\$dir\* /D /S /Y /F /l

}
function DoCopyRpt($dir) {
	#NOTE: the "\*" on target prevents prompting for "d"irectory or "f"ile
	"$sourcePath\rpt\$dir"

	cmd.exe /c xcopy $sourcePath\rpt\$dir $targetPath\rpt\$dir\* /D /S /Y /F /l

}

if($isReady){

	#we're going to show each directory as it's being copied to give a status
	$dirs = dir -Directory $sourcePath
	foreach ($dir in $dirs) {
		if($dir -eq "rpt") { exit }
		DoCopy($dir)
	}
	
	#rpt dir
	$dirs = dir -Directory $sourcePath\rpt
	foreach ($dir in $dirs) {
		DoCopyRpt($dir)

	}


	
	#Generate ListFile.txt for FTP to not have to list the files
	#gci $targetPath\* -recurse -force | Select-Object -exp FullName | Out-File $targetPath\FileList.txt

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
