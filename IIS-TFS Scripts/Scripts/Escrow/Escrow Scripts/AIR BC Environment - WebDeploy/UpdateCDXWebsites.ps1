<#
PURPOSE:
Deploy ProdBuild.zip to BC's Web0, and Report1

1. Download ProdBuild.zip from the primary Xceligent FTP Server
2. Extract to a temporary directory
3. Copy Production directory to Web0

CREATED:
2014.09.29 - ESH

UPDATED:


#>
# Set variables & constants
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
set-alias sz "$scriptPath\7z.exe" 
$scriptName = $MyInvocation.MyCommand.Name
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)
$logFile = "$scriptName-$timeDateStamp.log"

$prodBuildZipFile = "ProdBuild.zip"

# BEGIN FUNCTIONS ===========================================
function ShowScriptBegin()
{
	cls
	#SStart-Transcript -path $logFile -append
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
	#Stop-Transcript
}

function CreateTempDir
{
   $tmpDir = [System.IO.Path]::GetTempPath()
   $tmpDir = [System.IO.Path]::Combine($tmpDir, [System.IO.Path]::GetRandomFileName())
   [System.IO.Directory]::CreateDirectory($tmpDir) | Out-Null
   $tmpDir
}

function PromoteWebsite
{
	param ($sourceDir, $targetDir)
	
	if(!($sourceDir) -or !($targetDir))
	{
		"Missing Source or Target Directory parameters."
		return
	}	

	$tempDir = CreateTempDir
	$excludeExts = @("sln", "metaproj", "vspscc", "resx", "tmp", "vb", "vbproj", "cs", "csproj", "resx", "pdb", "bak", "user", "suo", "vssscc")
	$excludeDirs = @("obj", "RadControls", "Service References", "Web References", "My Project")

	Write-Host "Source Path: $sourceDir"
	Write-Host "Destination Path: $targetDir"
	Write-Host "Temp Path: $tempDir"
	
	# Verify that target directory exists, if not create it. #>
	if(!(Test-Path $targetDir)){ 
		New-Item -ItemType Directory -Force -Path $targetDir
	}
	
	#Copy source to temp dir...
	Copy-Item $sourceDir\* $tempDir -recurse -force

	# Remove unnecessary files by extension from source.#>
	for ($i=0; $i -lt $excludeDirs.length; $i++) {
		$currentDir = "\" + $excludeDirs[$i]
		$finalDir = $tempDir + $currentDir
		if(Test-Path $finalDir) { Remove-Item -Recurse -Force $finalDir }
	}

	# Remove unnecessary files by extension from source. #>
	for ($i=0; $i -lt $excludeExts.length; $i++) {
		$current = "*." + $excludeExts[$i]
		get-childitem $tempDir -include $current -recurse | foreach ($_) {remove-item $_.fullname -force}
	}

	# Copy files from source to destination (aka: The Beef #>
	Copy-Item $tempDir\* $targetDir -recurse -force	
	
	# Delete the temp directory created...
	Remove-Item -recurse -force $tempDir
}

function FTPDownloadProdBuild()
{
	param ($tempZipDir)
	$tempZipDir
	
	$ftpHost = "ftp.xceligent.com" 
	$user = "Acxiom" 
	$pass = "MoveItNow"
	
	$targetFile = "$tempZipDir\$prodBuildZipFile"
	$ftp = "ftp://{0}:{1}@{2}/{3}" -f $user, $pass, $ftpHost, $prodBuildZipFile
	"Connecting to: $ftpHost"

	$webclient = New-Object System.Net.WebClient
	$uri = New-Object System.Uri($ftp)
	"Downloading $targetFile... $targetFile"
	$webclient.DownloadFile($uri, $targetFile)
	
	$targetFile
}

function UnzipRollPackage()
{
	param ($fullPathToZip, $tempDeployDir)
	"Unzipping: $fullPathToZip to $tempDeployDir"
	sz x "-o$tempDeployDir" $fullPathToZip
}

function UpdateConfigFilesForBC()
{
	$timeDateStamp = $(get-date -f yyyy-MM-dd)
	$renameWebConfig = "Web.config_$timeDateStamp"

	#Web0
	#NOTE: Only need to change those web.configs (and global_config.asp) that make reference to 'cdx.xceligent.com'
	# Replacing it with 'cdxairtest.xceligent.com'

	$sourceWeb0GlobalConfig = "$scriptPath\Web0\wwwroot\global_config.asp"
	$sourceWeb0CDXWebConfig = "$scriptPath\Web0\wwwroot\CDX\Web.config"
	$sourceWeb0RPSWebConfig = "$scriptPath\Web0\wwwroot\ReportPortalService\Web.config"
	$renameWeb0GlobalConfig = "global_config.asp_$timeDateStamp"
	$targetWeb0GlobalConfig = "\\web0\d$\Inetpub\Production\global_config.asp"
	$targetWeb0CDXWebConfig = "\\web0\d$\Inetpub\Production\CDX\web.config"
	$targetWeb0RPSWebConfig = "\\web0\d$\Inetpub\Production\ReportPortalService\web.config"
	#Global_config.asp
	Rename-Item $targetWeb0GlobalConfig $renameWeb0GlobalConfig -Force -ErrorAction silentlycontinue  # No errors
	Copy-Item -Path $sourceWeb0GlobalConfig -Destination $targetWeb0GlobalConfig -Force
	#CDX web.config
	Rename-Item $targetWeb0CDXWebConfig $renameWebConfig -Force -ErrorAction silentlycontinue  # No errors
	Copy-Item -Path $sourceWeb0CDXWebConfig -Destination $targetWeb0CDXWebConfig -Force
	#ReportPortalService web.config
	Rename-Item $targetWeb0RPSWebConfig $renameWebConfig -Force -ErrorAction silentlycontinue  # No errors
	Copy-Item -Path $sourceWeb0RPSWebConfig -Destination $targetWeb0RPSWebConfig -Force

	#Report1
	$sourceReport1RGSWebConfig = "$scriptPath\Report1\ReportGenerationService\Web.config"
	$targetReport1RGSWebConfig = "\\Report1\c$\Inetpub\wwwroot\ReportGenerationService\web.config"
	Rename-Item $targetReport1RGSWebConfig $renameWebConfig -Force -ErrorAction silentlycontinue  # No errors
	Copy-Item -Path $sourceReport1RGSWebConfig -Destination $targetReport1RGSWebConfig -Force
}

# END FUNCTIONS ===========================================

# BEGIN SCRIPT ===========================================
ShowScriptBegin

#Create Temporary Zip Directory Location
$tempZipDir = CreateTempDir
$tempDeployDir = CreateTempDir

"Temp Zip Dir: $tempZipDir"
"Temp Deploy Dir: $tempDeployDir"

#Download BuildProd.zip from ftp.xceligent.com
$fullPathToZip = FTPDownloadProdBuild $tempZipDir

#Extract to Temporary Directory
UnzipRollPackage $fullPathToZip $tempDeployDir

#Promote CDX, and all others
$sourceDir = "$tempDeployDir\ProdBuild\Production"
$targetDir = "\\web0\d$\Inetpub\Production"
PromoteWebsite $sourceDir $targetDir

#Run Script to update AIR BC Web.Configs...


#Remove Temporary Directories
"Removing Temporary Directories created for the deployment... "
"Removing: $tempZipDir"
rm $tempZipDir

"Removing: $tempDeployDir"
rm $tempDeployDir

ShowScriptEnd
# END SCRIPT ===========================================


