#requires -version 2
<#
.SYNOPSIS
  ComicFilenameFilter.ps1

.DESCRIPTION
  Takes files in the given directory and removes the team and other needless items, and can inject the proper year.month into the filename

.PARAMETER directory
.PARAMETER comicDate

.NOTES
  Version:        1.0
  Author:         E.S.H.
  Creation Date:  3/27/2016
  Purpose/Change: Initial script development
  
.EXAMPLE
  ComicFilenameFilter "C:\Temp" "2016.05"
#>

Param (
	[Parameter(Mandatory=$true)]
	[AllowEmptyString()]
	[string] $directory
	,[Parameter(Mandatory=$false)]
	[AllowEmptyString()]
	[string] $comicDate
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
$replacements = @("2016"
	, "2017"
	, "2 covers"
	, "3 covers"
	, "4 covers"
	, "5 covers"
	, "6 covers"
	, "7 covers"
	, "Zone-Empire"
	, "Digital-Empire"
	, "The Last Kryptonian-DCP"
	, "Son of Ultron-Empire"
	, "Minutemen-Midas"
	, "Glorith-Novus-HD"
	, "Hourman-DCP"
	, "BlackManta-Empire"
	, "Pirate-Empire"
	, "RandomRipper"
	, "TLK-EMPIRE-HD"
	, "Webrip-DCP"
	, "webrip-DCP"
	, "AnHeroGold-Empire"
	, "Cypher 2.0-Empire"
	, "Minutemen-Faessla"
	, "d'argh-Empire"
	, "Oroboros-DCP"
	, "Digital"
	, "digital"
	, "Webrip"
	, "webrip"
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#-----------------------------------------------------------[Functions - Script Specific]------------------------------------------

function ComicFilenameFilter($directory, $comicDate) {
	$files = Get-ChildItem -Path $directory -File
	foreach ($file in $files) { 
		if(!$file.name) { continue; }
		$fileName = $file.name
		$directory = $file.DirectoryName
		$extension = $file.Extension  
		$fileDirectory = "$directory\$fileName"
		write-host "Filename: $fileDirectory"
		$beforeFilename = $fileName
		foreach($repacement in $replacements) {
			$fileName = $fileName.Replace($repacement, "")
			$fileName = $fileName.Replace(" (", "")
			$fileName = $fileName.Replace("(", "").Replace(")", "")
		}
		#If there is no change, no need to continue, so continue...
		if($beforeFilename -eq $fileName) { continue; }

		if($comicDate)
		{
			#Inject the Year/Month of the comic into the name, before the issue number...
			$issueNumberLength = 3
			$fileNameExt = $extension.length + $issueNumberLength
			$fileNameRightPosition = $fileName.length - $fileNameExt
			$fileNamePre = $fileName.substring(0, $fileNameRightPosition -1)
			$fileNameSuf = $fileName.substring($fileNamePre.length +1)
			$newFileName = "{0}.{1}.{2}" -f $fileNamePre, $comicDate, $fileNameSuf
		} else {
			$newFileName = $fileName
		}

		write-host "New File: $directory\$newFileName"
		#Get on with it already... rename the damned file!
		Rename-Item -Force "$fileDirectory" "$directory\$fileName"
	}
}

#-----------------------------------------------------------[Functions - Core]-----------------------------------------------------

function Main {
	#Begin primary code.
	$errorCode = 0
	try {
		ComicFilenameFilter $directory $comicDate
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
