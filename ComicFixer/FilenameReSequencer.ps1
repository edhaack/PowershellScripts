<#
===========================================================================
PURPOSE:

OVERVIEW:
1)
2)
3)

CREATED:
1.0 5/30/2015 - ESH - Initial release

UPDATED:
===========================================================================
#>

# BEGIN Parameters ===========================================
Param (
	[Parameter(Mandatory=$True)]
	[ValidateNotNull()]
	[string] $sourceDirectory,
	[Parameter(Mandatory=$True)]
	[ValidateNotNull()]
	[string] $stringToReplace
)
# END Parameters ===========================================

# BEGIN VARIABLES ===========================================
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)
$logFile = "$scriptName-$timeDateStamp.log"

# BEGIN FUNCTIONS ===========================================
function Main()
{
	$files = Get-ChildItem -Path "$sourceDirectory\*.*"
	$newNumber = 0
	foreach ($file in $files) { 
		if(!$file.name) { continue; }
		
		$newNumber++
		$newNumberString = $newNumber.ToString("00")
		
		$name = $file.name 
		write-host $sourceDirectory\$name
		$replaceWith = ".{0}." -f $newNumberString
		$newName = $name.Replace($stringToReplace, $replaceWith)
		write-host $sourceDirectory\$newName
		Rename-Item "$sourceDirectory\$name" "$sourceDirectory\$newName" -Force
	}

}

function ShowScriptBegin()
{
	cls
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
	
}
# END FUNCTIONS ===========================================

# BEGIN SCRIPT ===========================================
ShowScriptBegin

Main

ShowScriptEnd
# END SCRIPT ===========================================