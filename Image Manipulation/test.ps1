<#
CREATED: 2014.03.24 ESH

PARAMETERS:
	
EXAMPLE:
	
PURPOSE:

#>

#Script Parameters...
#param([string]$source = "C:", [string]$target = "C:")

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)

"
Script Start-Time: $startTime
"

# Functions

# Script Execution

$endTime = Get-Date
$elapsedTime = $endTime - $startTime

"
Complete at: $endTime

Duration:
{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours

# Script Execution - BEGIN
