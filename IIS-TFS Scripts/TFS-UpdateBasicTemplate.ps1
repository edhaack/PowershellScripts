<#
PURPOSE:
Update BasicTemplate.xsl (from Phill Woodward) : TFS, Dev, QA, UAT and Production environments.

OVERVIEW:
1) Get location of new Template file.
2) TFS Checkout 2 locations for the template
3) Copy to these locations
4) TFS Checkin both locations
5) Copy to Dev & QA Web Server(s)
6) FTP to Production FTP Server
---
On deployment server @ Xceligent.local (NetStandard)
1) Copy from FTP to location on deployment server (WebD at the time of this)
2) Execute script to update UAT and Production

CREATED:
2014.12.18 - ESH

UPDATED:


#>
# Set variables & constants
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
set-alias tf "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe"
$scriptName = $MyInvocation.MyCommand.Name
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)
$logFile = "$scriptName-$timeDateStamp.log"

$updatedBasicTemplate = "C:\TODO\BasicTemplate.xsl"
$basicTempateFilename = "BasicTemplate.xsl"

$localRoot = "D:\TFS\Portfolio\Product\CDX\Development\Development-Main\Xceligent.CDX"
$destination1 = "\Xsl\ExtraExtra"
$destination2 = "\ExtraExtra\xsl"

$path1 = "$localRoot$destination1"
$path2 = "$localRoot$destination2"

$qaRoot = "\\xdwebtest\devroot\CDX\"
$qaLocation1 = "$qaRoot$destination1"
$qaLocation2 = "$qaRoot$destination2"

$ftp = "ftp://ftp.xceligent.com/" 
$user = "Acxiom" 
$pass = "MoveItNow"

# BEGIN FUNCTIONS ===========================================
function ShowScriptBegin()
{
	cls
	Start-Transcript -path $logFile -append
	"
	Script Start-Time: $startTime
	"
}

function ShowScriptEnd()
{
	$endTime = Get-Date
	$elapsedTime = $endTime - $startTime
	"
	Complete at: $endTime

	Duration:
	{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours
	Stop-Transcript
}

function MainFunction()
{
	<##Update location 1#>
	tf checkout "$path1\$basicTempateFilename"
	Copy-Item $updatedBasicTemplate $path1
	tf checkin /comment:"Updated Template from Phill Woodward" "$path1\$basicTempateFilename" /noprompt /override:"asdf"
	
	#Update location 2#>
	tf checkout "$path2\$basicTempateFilename"
	Copy-Item $updatedBasicTemplate $path2
	tf checkin /comment:"Updated Template from Phill Woodward" "$path2\$basicTempateFilename" /noprompt /override:"asdf"
	
	#Copy new template file to QA.
	Copy-Item $updatedBasicTemplate $qaLocation1
	Copy-Item $updatedBasicTemplate $qaLocation2
	exit
	
	#FTP The new template file, to be available in UAT & Prod.
	"FTP'ing zip file to: $ftp"
	$webclient = New-Object System.Net.WebClient 
	$ftpWithFile = $ftp + $updatedBasicTemplate
	$webclient.Credentials = New-Object System.Net.NetworkCredential($user,$pass) 
	$uri = New-Object System.Uri($ftpWithFile) 
	$webclient.UploadFile($uri, $zipFilePath) 
}

# END FUNCTIONS ===========================================

# BEGIN SCRIPT ===========================================
ShowScriptBegin

MainFunction

ShowScriptEnd
# END SCRIPT ===========================================

  
