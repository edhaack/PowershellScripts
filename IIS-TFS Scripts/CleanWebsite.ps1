<#
PURPOSE:
Remove source code and other unneccessary files from web server

OVERVIEW:
1) Get directory path to clean
2) Loop thru each subdirectory, 
2a) check for file types
2b) if found, delete

CREATED:
2014.12.22 - ESH

UPDATED:

#>
Param (
	[Parameter(Mandatory=$True)]
	[ValidateNotNull()]
	$webPath
)

# Set variables & constants
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)
$logFile = "$scriptName-$timeDateStamp.log"

$cdxDirectories = @("CDX", "Demographics", "MapSearch", "ParcelLocator", "ReportPortalService", "ServicePortalWeb", "xceligentApp")

$excludeExts = @("sln", "metaproj", "vspscc", "resx", "tmp", "vb", "vbproj", "cs", "csproj", "resx", "pdb", "bak", "user", "suo", "vssscc")
$excludeDirs = @("obj", "RadControls", "Service References", "Web References", "My Project")


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
	#Loop thru each directory in array...
	
	#Loop thru each file in sub-directory structure...
	
	#If file match with item in file extention array, delete
	
	#if director match with item in dir array, remove
	
	
}

# END FUNCTIONS ===========================================

# BEGIN SCRIPT ===========================================
ShowScriptBegin

MainFunction

ShowScriptEnd
# END SCRIPT ===========================================

  
