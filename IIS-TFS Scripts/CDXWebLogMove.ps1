<#
PURPOSE:
Move CDX Web Log files for Web0 and Web4.

OVERVIEW:
1) WEB0: Loop thru each file in main Log Directory.
2) If file modified date < current date, move to Destination 
3) WEB4: Loop thru each file in main Log Directory.
4) If file modified date < current date, move to Destination 

CREATED:
2015.01.05 - ESH

UPDATED:

#>

# Set variables & constants
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name

$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)
$logFile = "$scriptName-$timeDateStamp.log"

$web0Source = "\\Web0\E$\LogFiles\W3SVC1941846645"
$web0Target = "\\ftp\ftp2\Xceligent\CDX\Web Logs\Web0"

$web4Source = "\\Web4\E$\LogFiles\W3SVC1941846645"
$web4Target = "\\ftp\ftp2\Xceligent\CDX\Web Logs\Web4"

$numberOfDaysAgo = 2


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
	#WEB0
	MoveWebLogs $web0Source $web0Target
	#WEB4
	MoveWebLogs $web4Source $web4Target
}

function MoveWebLogs($source, $target)
{
	$newFiles = Get-ChildItem $source\*.* | Where{$_.LastWriteTime -lt (Get-Date).AddDays(-$numberOfDaysAgo)}
	foreach ($file in $newFiles)
	{
		$targetPath = $target
		if ($file)
		{
			New-Item $targetPath -Type file -Force -WhatIf
			Move-Item $file $targetPath -Force -WhatIf
		}
	}
}

# END FUNCTIONS ===========================================

# BEGIN SCRIPT ===========================================
ShowScriptBegin

MainFunction

ShowScriptEnd
# END SCRIPT ===========================================

  
