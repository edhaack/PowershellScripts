#requires -version 2
<#
.SYNOPSIS
  CreateNewModuleScaffold.ps1

.DESCRIPTION
  <Brief description of script>

.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>

.INPUTS
  <Inputs if any, otherwise state None>

.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>

.NOTES
  Version:        1.0
  Author:         E.S.H.
  Creation Date:  3/27/2016
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

Param (
	[string] $Path = 'C:\sc\PSStackExchange',
	[string] $ModuleName = 'PSStackExchange',
	[string] $Author = 'RamblingCookieMonster',
	[string] $Description = 'PowerShell module to query the StackExchange API'
)

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd.HH.mm)
$logFile = "$scriptName-$timeDateStamp.log"
$doOutputFile = $false
#For Exceptions
$shouldSendEmailOnException = $false
$smtpServer = "smtp.xceligent.org"
$emailFrom = "teamcity@xceligent.com"
$emailTo = "ehaack@xceligent.com"

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#-----------------------------------------------------------[Functions - Script Specific]------------------------------------------


#-----------------------------------------------------------[Functions - Core]-----------------------------------------------------

function Main {
	#Begin primary code.
	$errorCode = 0
	try {
		#$Path = 'C:\sc\PSStackExchange'
		#$ModuleName = 'PSStackExchange'
		#$Author = 'RamblingCookieMonster'
		#$Description = 'PowerShell module to query the StackExchange API'

		# Create the module and private function directories
		mkdir $Path\$ModuleName
		mkdir $Path\$ModuleName\Private
		mkdir $Path\$ModuleName\Public
		mkdir $Path\$ModuleName\en-US # For about_Help files
		mkdir $Path\Tests

		#Create the module and related files
		New-Item "$Path\$ModuleName\$ModuleName.psm1" -ItemType File
		New-Item "$Path\$ModuleName\$ModuleName.Format.ps1xml" -ItemType File
		New-Item "$Path\$ModuleName\en-US\about_PSStackExchange.help.txt" -ItemType File
		New-Item "$Path\Tests\PSStackExchange.Tests.ps1" -ItemType File
		New-ModuleManifest -Path $Path\$ModuleName\$ModuleName.psd1 `
						   -RootModule $Path\$ModuleName\$ModuleName.psm1 `
						   -Description $Description `
						   -PowerShellVersion 3.0 `
						   -Author $Author `
						   -FormatsToProcess "$ModuleName.Format.ps1xml"
	}
	catch {
		HandleException $_ 
		$errorCode = 1
	}
	finally {
	
	}
	if(!($errorCode -eq 0)) {
		Write-Host "Exiting with error $errorCode"
		exit $errorCode 
	}
}

function HandleException($exceptionObject) {
	$errorMessageBuilder = New-Object System.Text.StringBuilder
	$errorMessageBuilder.Append("$scriptName : An error occurred`r`n`r`n")
	$errorMessageBuilder.Append("Exception Type: $($exceptionObject.Exception.GetType().FullName)`r`n")
	$errorMessageBuilder.Append("Exception Message: $($exceptionObject.Exception.Message)`r`n")
	$errorMessageBuilder.Append("`r`n")

	$errorMessage = $errorMessageBuilder.ToString()

    Write-Host "Caught an exception:" -ForegroundColor Red
	Write-Host $errorMessage -ForegroundColor Red
	
	if($shouldSendEmailOnException -eq $true){
		Write-Host "Sending email to: $emailTo"
		
		$emailMessage = New-Object System.Net.Mail.MailMessage( $emailFrom , $emailTo )
		$emailMessage.Subject = "{0}-{1} Failure" -f $scriptPath, $scriptName
		$emailMessage.IsBodyHtml = $false
		$emailMessage.Body = $errorMessage

		$SMTPClient = New-Object System.Net.Mail.SmtpClient( $smtpServer )
		$SMTPClient.Send( $emailMessage )
	}
}

function ShowScriptBegin() {
	cls
	if($doOutputFile){
		Start-Transcript -path $logFile -append
	}
	"
	Script Start-Time: $startTime
	"
}

function ShowScriptEnd() {
	$endTime = Get-Date
	$elapsedTime = $endTime - $startTime
	"
	Complete at: $endTime

	Duration:
	{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours
	if($doOutputFile){
		Stop-Transcript
	}
	
#	Write-Host "Press any key to continue ..."
#	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

ShowScriptBegin
Main
ShowScriptEnd
