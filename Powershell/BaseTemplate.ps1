<#
PURPOSE:

OVERVIEW:
1) 

CREATED:
2014.12.18 - ESH

UPDATED:

#>
Param (
	[Parameter(Mandatory=$True)]
	[ValidateNotNull()]
	$sqlServer
)

# Set variables & constants
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
set-alias tf "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe"
$scriptName = $MyInvocation.MyCommand.Name
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)
$logFile = "$scriptName-$timeDateStamp.log"

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
	
	Write-Host "Press any key to continue ..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function MainFunction()
{

}

# END FUNCTIONS ===========================================

# BEGIN SCRIPT ===========================================
ShowScriptBegin

MainFunction

ShowScriptEnd
# END SCRIPT ===========================================

  
