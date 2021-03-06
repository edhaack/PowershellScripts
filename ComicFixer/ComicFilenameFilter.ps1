#requires -version 2
<#
.SYNOPSIS
  Comic book filename cleaner-upper

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
  Creation Date:  3/25/2016
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

#Param (
#	[Parameter(Mandatory=$true)]
#	[AllowEmptyString()]
#	[string] $parameterName
#)

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

$replacements = @("2016", "2 covers", "3 covers", "4 covers", "5 covers", "Webrip", "Digital", "Zone-Empire", "The Last Kryptonian-DCP", "Son of Ultron-Empire", "Minutemen-Midas", "Glorith-Novus-HD", "Hourman-DCP", "BlackManta-Empire", "Webrip-DCP")

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#-----------------------------------------------------------[Functions - Script Specific]------------------------------------------

function ComicBookFilenameFixer($directory) {
$files = Get-ChildItem -Path $directory -File

	foreach ($file in $files) { 
		if(!$file.name) { continue; }
		$fileName = $file.name
		$directory = $file.DirectoryName
		$fileDirectory = "$directory\$fileName"
		write-host "Filename: $fileDirectory"
		
		foreach($repacement in $replacements) {
			$replacement
			$replacement = $replacement.ToLower()
			$newFileName = $fileName.Replace($repacement, "")
			#$newFileName = $newFileName.Replace(" (", "")
			#$fileName = $fileName.Replace(")", "")
			write-host "New File: $directory\$newFileName"
			
			Rename-Item -Force "$fileDirectory" "$directory\$newFileName"
		}

	}
}

#-----------------------------------------------------------[Functions - Core]-----------------------------------------------------

Function Main {
	#Begin primary code.
	$errorCode = 0
	try {
		ComicBookFilenameFixer "C:\Temp"
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
