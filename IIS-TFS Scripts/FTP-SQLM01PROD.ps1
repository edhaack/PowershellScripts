<#
PURPOSE: 

FTP given file to target for AIR BC's BCMon1 FTP Server.

CREATED: 2014.09.22 - ESH

#>
Param (
	[Parameter(Mandatory=$True)]
	[ValidateNotNull()]
	$sourceDir,
	[Parameter(Mandatory=$True)]
	[ValidateNotNull()]
	$targetDir
)

# Set variables & constants
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)
$logFile = "$scriptName-$timeDateStamp.log"

$ftp = "ftp://139.146.244.2/" 
$user = "xceligentIT" 
$pass = "itnKnpeV60V629AJWz4I"

$webclient = New-Object System.Net.WebClient 
$webclient.Credentials = New-Object System.Net.NetworkCredential($user,$pass) 

function ShowScriptEnd()
{
	$endTime = Get-Date
	$elapsedTime = $endTime - $startTime
	 
	"
	Complete at: $endTime
	 
	Duration:
	{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours
 	exit
}

function TransferFile($filePath, $fileName)
{
	"Transferring: $filePath, $fileName"

	$ftpWithFile = "$ftp$targetDir\$fileName"
	$uri = New-Object System.Uri($ftpWithFile) 
	$webclient.UploadFile($uri, $filePath) 
}


# BEGIN SCRIPT ===========================================
cls
"ftp url: $ftpHost"

"
Script Start-Time: $startTime
"

"Source: " + $sourceDir
"Target: " + $targetDir

#Test if source directory exists...
if( -not(Test-Path $sourceDir))
{
	"Missing Source Directory"
	ShowScriptEnd
}

#Loop thru each file and xfer
gci $sourceDir | Foreach-Object{ TransferFile $_.FullName $_.Name }

# END SCRIPT ===========================================
ShowScriptEnd

