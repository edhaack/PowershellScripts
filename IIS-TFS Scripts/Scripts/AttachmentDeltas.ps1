<#
CREATED: 2014.03.24 ESH
 
PARAMETERS:
     
EXAMPLE:
     
PURPOSE:
 
#>
 
$isDebug = "true"
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)
 
"
Script Start-Time: $startTime
"
 
# Functions
 
# Script Execution - BEGIN

cls
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$numberOfDaysAgo = 60
$attachmentsBasePath = "P:\ApplicationImages_Prod"
$DeltasTarget = "Attachments-Deltas"
$targetAttachmentsPath = "P:\$DeltasTarget\Attachments"

#7zip...
set-alias sz "C:\Program Files\7-Zip\7z.exe"
$zipFilePath = "$attachmentsBasePath\AttachmentDeltas.zip"
$listFilesTxt = "$attachmentsBasePath\AttachmentsDeltas.txt"

#Path to copy zip file
$zipTargetPath = "\\ftp\FTP2\Xceligent\Departments\IT\CDX-Attachments"

#ftp server  - future referece
$ftp = "ftp://ftp.xceligent.com/" 
$user = "CDX-Attachments" 
$pass = "Xceligent0508"



$thirtyDaysAgo = (Get-Date).AddDays(-$numberOfDaysAgo).ToString("d")
Write-Host "Date to copy: $thirtyDaysAgo

getting list of files... "

#/d +30 doesn't seem to work ???
$newFiles = cmd /c forfiles /p "$attachmentsBasePath\Attachments" /s /d +$thirtyDaysAgo /c "cmd /c if @isdir==FALSE echo @path"
$newFiles = $newFiles -replace "`"", ""


#Zip file needs to start from a base directory to maintain directory structure...
#1. Create base directories in order to copy
$attachmentsTargetRootDir = "P:\Attachments-Deltas"
$attachmentsTargetDir = "$attachmentsTargetRootDir\Attachments"
$reportDir = "\rpt"

<#for($i=0;$i -le 999; $i++){
	$newDir = $i.ToString("000")
	New-Item -ItemType Directory -Force -Path $attachmentsTargetDir\$newDir | Out-Null
	New-Item -ItemType Directory -Force -Path $attachmentsTargetDir$reportDir\$newDir | Out-Null
}#>

#2. Copy $newFiles array of file paths to target
foreach ($file in $newFiles)
{
	#P:\ApplicationImages_Prod\Attachments\174\4338174.pdf
	
	$targetPath = $file -replace "ApplicationImages_Prod", $DeltasTarget
	$targetPath
	if ($file)
	{
		New-Item $targetPath -Type file -Force
		Copy-Item $file $targetPath -Recurse -Force
	}
}

#Save list of files to txt file, for 7zip...
#"Saving delta file paths to $listFilesTxt"
#$newFiles | Out-File $listFilesTxt
#(gc $listFilesTxt | select -Skip 1 ) | sc $listFilesTxt #The first item is a blank line, not supported by 7Zip's: List of Files, file.

#Zip files, prep for FTP...
"Zipping files"
#sz a $zipFilePath `@$listFilesTxt -tzip

sz a $zipFilePath $targetAttachmentsPath -tzip

#Delete the temporary zip location
Remove-Item $attachmentsTargetRootDir -Recurse -Force


#Copy to FTP Server...
if($isDebug -eq "false" ) {
	"Copying $zipFilePath to $zipTargetPath  "
	Copy-Item $zipFilePath $zipTargetPath 
}

# Script Execution - END
 
$endTime = Get-Date
$elapsedTime = $endTime - $startTime
 
"
Complete at: $endTime
 
Duration:
{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours
 
#END

