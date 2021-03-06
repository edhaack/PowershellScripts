<#
PURPOSE:

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

function HandleException($exceptionObject){

	$errorMessageBuilder = New-Object System.Text.StringBuilder
	$errorMessageBuilder.Append("An error occurred transferring media files`r`n`r`n")
	$errorMessageBuilder.Append("Exception Type: $($exceptionObject.Exception.GetType().FullName)`r`n")
	$errorMessageBuilder.Append("Exception Message: $($exceptionObject.Exception.Message)`r`n")
	$errorMessageBuilder.Append("`r`nPlease check BCMon1 `r`n")

	$errorMessage = $errorMessageBuilder.ToString()

    write-host "Caught an exception:" -ForegroundColor Red
	Write-Host $errorMessage -ForegroundColor Red
}

# END FUNCTIONS ===========================================

# BEGIN SCRIPT ===========================================
ShowScriptBegin




ShowScriptEnd
# END SCRIPT ===========================================
