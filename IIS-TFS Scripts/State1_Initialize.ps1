<#
PURPOSE:
Creates and Set Shares for the Media Server

CREATED:
2014.10.23 - ESH

UPDATED:

#>

# Set variables & constants
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)
$logFile = "$scriptName-$timeDateStamp.log"


# BEGIN FUNCTIONS ===========================================
function ShowScriptBegin ()
{
	cls
	$ErrorActionPreference="SilentlyContinue"
	Stop-Transcript | out-null
	$ErrorActionPreference = "Continue" # or "Stop"
	Start-Transcript -path $logFile -append
	"
	-----------------------------------------------------
	$scriptName
	Start-Time: $startTime
	Logging to: $logFile
	"
}

function ShowScriptEnd ()
{
	$endTime = Get-Date
	$elapsedTime = $endTime - $startTime
	"
	-----------------------------------------------------
	Complete at: $endTime

	Duration:
	{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours
	Stop-Transcript
	Exit
}

function HandleException($exceptionObject)
{

	$errorMessageBuilder = New-Object System.Text.StringBuilder
	$errorMessageBuilder.Append("An error occurred transferring media files`r`n`r`n")
	$errorMessageBuilder.Append("Exception Type: $($exceptionObject.Exception.GetType().FullName)`r`n")
	$errorMessageBuilder.Append("Exception Message: $($exceptionObject.Exception.Message)`r`n")
	$errorMessageBuilder.Append("`r`nPlease check BCMon1 `r`n")

	$errorMessage = $errorMessageBuilder.ToString()

    write-host "Caught an exception:" -ForegroundColor Red
	Write-Host $errorMessage -ForegroundColor Red
}

function CreateDirectory($dirPath)
{
	#Check of given path already exists...
	if(!(Test-Path $dirPath))
	{
		#Create the directory path...
		Write-Host "Creating directory: $dirPath"
		New-Item -ItemType Directory -Force -Path $dirPath | Out-Null
	}
}

function CreateShare($dirPath, $shareName, $shareDescription)
{
	Write-Host "Creating Share: $shareName"
	
	#Check that dir exists...
	if(!(Test-Path $dirPath))
	{ 
		Write-Host "Unable to locate: $dirName"
		return 
	}
	net share "$shareName=$dirPath" "/GRANT:Everyone,FULL" /unlimited /CACHE:none /REMARK:"$shareDescription"
}

# END FUNCTIONS ===========================================

# BEGIN SCRIPT ===========================================
ShowScriptBegin

#Create the directory structures...
$rootDirectory = "P:"

CreateDirectory "$rootDirectory\ActiveReports_Prod"
CreateDirectory "$rootDirectory\ActiveReports_Prod\Demographics"
CreateDirectory "$rootDirectory\ActiveReports_Prod\SavedReports"
CreateDirectory "$rootDirectory\ApplicationImages_Prod"
CreateDirectory "$rootDirectory\ApplicationImages_Prod\Attachments"
#sub-dirs handled below...
CreateDirectory "$rootDirectory\ApplicationImages_Prod\BranchImages"
CreateDirectory "$rootDirectory\ApplicationImages_Prod\CDXMailAttachments"

CreateDirectory "$rootDirectory\ApplicationImages_Prod\ExtraExtraAttachments"
CreateDirectory "$rootDirectory\ApplicationImages_Prod\TenantBranchImages"
CreateDirectory "$rootDirectory\ApplicationImages_Prod\TenantLogos"
CreateDirectory "$rootDirectory\ApplicationImages_Prod\XmailAttachments"
CreateDirectory "$rootDirectory\PhotoImportSpace"
CreateDirectory "$rootDirectory\CDX_Direct"
CreateDirectory "$rootDirectory\CDX_Direct\CDXDirect_FileExplorer"
CreateDirectory "$rootDirectory\CDX_Direct\GlobalPhotos"
CreateDirectory "$rootDirectory\CDX_Direct\GlobalPhotos\Gradients"
CreateDirectory "$rootDirectory\CDX_Direct\GlobalPhotos\Icons"
CreateDirectory "$rootDirectory\CDX_Direct\Templates"
CreateDirectory "$rootDirectory\CDX_Direct\Templates\Default"
CreateDirectory "$rootDirectory\CDX_Direct\Templates\Default\CustomStyle"
CreateDirectory "$rootDirectory\CDX_Direct\Templates\Default\CustomStyle\InProcess"
CreateDirectory "$rootDirectory\CDX_Direct\Templates\Default\Photos"
CreateDirectory "$rootDirectory\CDX_Direct\Templates\Default\Photos\DefaultPhotos"
CreateDirectory "$rootDirectory\CDX_Direct\Templates\Default\Photos\UserPhotos"
CreateDirectory "$rootDirectory\CDX_Direct\Templates\Default\SavedSearches"
CreateDirectory "$rootDirectory\Extracts_Prod"
CreateDirectory "$rootDirectory\FeeSchedules_Prod"
CreateDirectory "$rootDirectory\MapFiles"
CreateDirectory "$rootDirectory\MarketAreaMaps_Prod"
CreateDirectory "$rootDirectory\PrivateBranding_Prod"
CreateDirectory "$rootDirectory\PrivateBranding_Prod\CDXDirectLogs"
CreateDirectory "$rootDirectory\PrivateBranding_Prod\Settings"
CreateDirectory "$rootDirectory\PrivateBranding_Prod\StyleSheets"
CreateDirectory "$rootDirectory\PrivateBranding_Prod\Templates"
CreateDirectory "$rootDirectory\WebCharts_Prod"

$cdxMailAttachmentsDir = "$rootDirectory\ApplicationImages_Prod\CDXMailAttachments"
$attachmentsDir = "$rootDirectory\ApplicationImages_Prod\Attachments"
$reportDir = "\rpt"
#Create dir structures for Attachments...
#New-Item -ItemType Directory -Force -Path $attachmentsDir
for($i=0;$i -le 999; $i++){
	$newDir = $i.ToString("000")
	#Attachments (CDX)
	New-Item -ItemType Directory -Force -Path $attachmentsDir\$newDir | Out-Null
	New-Item -ItemType Directory -Force -Path $attachmentsDir$reportDir\$newDir | Out-Null
	#CDX Mail Attachments
	New-Item -ItemType Directory -Force -Path $cdxMailAttachmentsDir\$newDir | Out-Null
}

#Set Everyone Permissions on the directories themselves...
icacls "$rootDirectory\*" /grant Everyone:F

<#
Shares
#>
CreateShare "$rootDirectory\ActiveReports_Prod" "ActiveReports_Prod" "ActiveReports"
CreateShare "$rootDirectory\ApplicationImages_Prod" "ApplicationImages_Prod"
CreateShare "$rootDirectory\PhotoImportSpace" "PhotoImportSpace"
CreateShare "$rootDirectory\CDX_Direct" "CDX_Direct"
CreateShare "$rootDirectory\FeeSchedules_Prod" "FeeSchedules_Prod"
CreateShare "$rootDirectory\PrivateBranding_Prod" "PrivateBranding_Prod"
CreateShare "$rootDirectory\Extracts_Prod" "Extracts_Prod"
CreateShare "$rootDirectory\MapFiles" "MapFiles_Prod"
CreateShare "$rootDirectory\MarketAreaMaps_Prod" "MarketAreaMaps_Prod"
CreateShare "$rootDirectory\WebCharts_Prod" "WebCharts_Prod"

Get-WmiObject -Class Win32_Share

ShowScriptEnd
# END SCRIPT ===========================================
