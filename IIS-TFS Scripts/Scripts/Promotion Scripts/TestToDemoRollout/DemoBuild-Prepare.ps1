<#
Purpose: Get current "Test" Web site files, zip and ftp.
Created: 2014.01.17 ESH

This is the first part of a Demo Deployment Process. The second exists on DB3 (TODO) 
#>

<#  --VARIABLES BEGIN-- #>

<# The Main CDX Version #>
$mainCDXVersion = "9.1"
<# The set of characters within the web.config file(s) to change to the correct version #>
$webConfigJsVersionReplace = "##JSVERSION##" 

set-alias sz "C:\Program Files\7-Zip\7z.exe" 
$startTime = Get-Date
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#ftp server 
$ftp = "ftp://ftp.xceligent.com/" 
$user = "Acxiom" 
$pass = "MoveItNow"

<#  Test Server Root Location #>
$xdWebTestServerC = "\\xdwebtest\c$"
$xdReportingServerC = "\\xdreportingi01\c$"
<#  Test Server's Root Website Directory #>
$sourceWebDir = $xdWebTestServerC + "\devroot"

<#  Local directory to copy to #>
$rollPackageDestinationDir = "C:\xcopy_remote"
$prodBuildZipFile = "ProdBuild.zip"
$zipFilePath = $rollPackageDestinationDir + "\" + $prodBuildZipFile

<#  ProdBuild/ProdBuild_OLD Directories #>
$prodBuildDir = $rollPackageDestinationDir + "\ProdBuild"
$prodBuildOldDir = $rollPackageDestinationDir + "\ProdBuild_OLD"
$prodBuildProductionDir = $prodBuildDir + "\Production"

<# Build Config Files #>
$tbcfDir = "\The Build Config Files"
$cdx = "CDX"
$rgs = "ReportGenerationService"
$rps = "ReportPortalService"
$spw = "ServicePortalWeb"
$uatConfig = "UAT.Web.Config"
$prodConfig = "PROD.Web.Config"
$webConfig = "Web.Config"

$scriptTbcf = $scriptPath + $tbcfDir
$DateStr = Get-Date -format yyyy.M.d
$jsVersion = $mainCDXVersion +"-" + $DateStr
$tbcfDemoTarget = $prodBuildDir +"\The Build Config Files\Demo Build Config Files"
$tbcfProdTarget = $prodBuildDir +"\The Build Config Files\Prod Build Config Files"

$srcWebConfigDir = $scriptPath + "\WebConfigFiles"
$cdxDemoWebConfigSource = $srcWebConfigDir + "\"+ $cdx +"\" + $uatConfig
$cdxProdWebConfigSource = $srcWebConfigDir + "\"+ $cdx +"\" + $prodConfig
$rgsDemoWebConfigSource = $srcWebConfigDir + "\"+ $rgs +"\" + $uatConfig
$rgsProdWebConfigSource = $srcWebConfigDir + "\"+ $rgs +"\" + $prodConfig
$rpsDemoWebConfigSource = $srcWebConfigDir + "\"+ $rps +"\" + $uatConfig
$rpsProdWebConfigSource = $srcWebConfigDir + "\"+ $rps +"\" + $prodConfig
$spwDemoWebConfigSource = $srcWebConfigDir + "\"+ $spw +"\" + $uatConfig
$spwProdWebConfigSource = $srcWebConfigDir + "\"+ $spw +"\" + $prodConfig

$cdxDemoWebConfigTarget = $tbcfDemoTarget + "\"+ $cdx +"\" + $webConfig
$cdxProdWebConfigTarget = $tbcfProdTarget + "\"+ $cdx +"\" + $webConfig
$rgsDemoWebConfigTarget = $tbcfDemoTarget + "\"+ $rgs +"\" + $webConfig
$rgsProdWebConfigTarget = $tbcfProdTarget + "\"+ $rgs +"\" + $webConfig
$rpsDemoWebConfigTarget = $tbcfDemoTarget + "\"+ $rps +"\" + $webConfig
$rpsProdWebConfigTarget = $tbcfProdTarget + "\"+ $rps +"\" + $webConfig
$spwDemoWebConfigTarget = $tbcfDemoTarget + "\"+ $spw +"\" + $webConfig
$spwProdWebConfigTarget = $tbcfProdTarget + "\"+ $spw +"\" + $webConfig

<#  --VARIABLES END-- #>

<#	--FUNCTIONS--	#>
function CopyWebConfig($source, $target){
	Write-Output "Copying: $source to $target"
	
	#Mark Target web.configs as ReadOnly...	
	sp $source IsReadOnly $false	
	sp $target IsReadOnly $false	
	
	Copy-Item $source $target -force
}

<#	--FUNCTIONS--	#>
	
<#  --SCRIPT BEGIN-- #>
"
Begin the procedures to build roll package from Test Environment: $startTime
 Will copy sites/services:
  - CDX
  - ReportPortalService
  - ServicePortalService
  - ReportGenerationService
 locally, then zip up and FTP.
 
"

<# Verify that working directory exists, if not create it. #>
if(!(Test-Path $rollPackageDestinationDir)){ 
	"Creating $rollPackageDestinationDir
	"
	New-Item -ItemType Directory -Force -Path $rollPackageDestinationDir
}

<#  Remove the ProdBuild_OLD Directory #>
if(Test-Path $prodBuildOldDir){ 
	"Deleting old build from: $prodBuildOldDir
	"
	Remove-Item -Recurse -Force $prodBuildOldDir
}

<#  Remove existing ProdBuild directory #>
if(Test-Path $prodBuildDir){ 
	"Removing $prodBuildDir
	"
	Remove-Item -Recurse -Force $prodBuildDir
}

<#  Create ProdBuild directory #>
"Created directory: $prodBuildDir

"

New-Item -ItemType Directory -Force -Path $prodBuildDir
New-Item -ItemType Directory -Force -Path $prodBuildProductionDir

<# Copy tbcf files directory #>
"Copying 'The Build Configuration Files' to: $prodBuildDir
 "
Copy-Item $scriptTbcf $prodBuildDir -recurse -Force

<# Copy the web.configs from the Solution Folder locations into the TBCF locations #>
CopyWebConfig $cdxDemoWebConfigSource $cdxDemoWebConfigTarget
CopyWebConfig $rgsDemoWebConfigSource $rgsDemoWebConfigTarget
CopyWebConfig $rpsDemoWebConfigSource $rpsDemoWebConfigTarget
CopyWebConfig $spwDemoWebConfigSource $spwDemoWebConfigTarget

CopyWebConfig $cdxProdWebConfigSource $cdxProdWebConfigTarget
CopyWebConfig $rgsProdWebConfigSource $rgsProdWebConfigTarget
CopyWebConfig $rpsProdWebConfigSource $rpsProdWebConfigTarget
CopyWebConfig $spwProdWebConfigSource $spwProdWebConfigTarget

<# BEGIN: Edit the web.config file(s), updating the Javascript Version - to prevent caching & add versioning to each of the loaded .js script files...#>

<# CDX: Javascript Version Update #>
	
(Get-Content $cdxDemoWebConfigTarget) | Foreach-Object {$_ -replace $webConfigJsVersionReplace, $jsVersion} | Set-Content $cdxDemoWebConfigTarget
(Get-Content $cdxProdWebConfigTarget) | Foreach-Object {$_ -replace $webConfigJsVersionReplace, $jsVersion} | Set-Content $cdxProdWebConfigTarget

<# END: Edit the web.config file(s), updating the Javascript Version - to prevent caching & add versioning to each of the loaded .js script files...#>

<#  Copy files from Test Web Server(s) to Local #>
"Copying files from Test to: CDX"
Robocopy $sourceWebDir\CDX $prodBuildProductionDir\CDX *.* /mir /log+:ProdBuild.log

"Copying files from Test to: ReportPortalService"
Robocopy $sourceWebDir\ReportPortalService $prodBuildProductionDir\ReportPortalService *.* /mir /log+:ProdBuild.log

"Copying files from Test to: ServicePortalWeb"
Robocopy $sourceWebDir\ServicePortalWeb $prodBuildProductionDir\ServicePortalWeb *.* /mir /log+:ProdBuild.log

"Copying files from Test to: ReportGenerationService"
Robocopy $xdReportingServerC\inetpub\wwwroot\ReportGenerationService $prodBuildProductionDir\ReportGenerationService *.* /mir /log+:ProdBuild.log

<#  Zip Local Site Dirs/Files #>
"Zipping up the roll package"
if(Test-Path $zipFilePath){ 
	"Deleting old build zip from: $zipFilePath"
	Remove-Item -Recurse -Force $zipFilePath
}
sz a $zipFilePath $prodBuildDir -tzip

<#  FTP Zip file to Demo Environment #>
"FTP'ing zip file to: $ftp"
$webclient = New-Object System.Net.WebClient 
$ftpWithFile = $ftp + $prodBuildZipFile
$webclient.Credentials = New-Object System.Net.NetworkCredential($user,$pass) 
$uri = New-Object System.Uri($ftpWithFile) 
$webclient.UploadFile($uri, $zipFilePath) 

$endTime = Get-Date

$elapsedTime = $endTime - $startTime

"
Duration:
{0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds
"
The roll package '$prodBuildZipFile' has been uploaded to the FTP Server at the hosting facility.
If needed, the roll package can also be found here: $zipFilePath

Done.
" 

<#  --SCRIPT END-- #>
