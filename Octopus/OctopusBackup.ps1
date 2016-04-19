#requires -version 2
<#
.SYNOPSIS
  OctopusBackup.ps1

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
  .\OctopusBackup "E:\Octopus-Backups"
#>

Param (
	[Parameter(Mandatory=$true)]
	[string] $backupDirectoryRoot
)

#$backupDirectoryRoot = "E:\Octopus-Backups"

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

set-alias sz "$scriptPath\7z.exe"

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#-----------------------------------------------------------[Functions - Script Specific]------------------------------------------

function OctopusBackup($backupDirectoryRoot){
	$backupTimeStamp = $(Get-Date -Format yyyy.MM.dd)
	$backupDirectory = "{0}\{1}" -f $backupDirectoryRoot, $backupTimeStamp
	$sqlDirectory = "{0}\SQL" -f $backupDirectory
	$octopusDataDirectory = "{0}\OctopusData" -f $backupDirectory

	# Create Backup Directories
	if(Test-Path $backupDirectory) { Remove-Item $backupDirectory -force -recurse}
	New-Item $backupDirectory -ItemType Directory
	New-Item $sqlDirectory -ItemType Directory
	New-Item $octopusDataDirectory -ItemType Directory

	# Backup the SQL Database
	$sqlInstance = "localhost"
	$databaseName = "Octopus"
	$bakFile = "{0}\Octopus.{1}.bak" -f $sqlDirectory, $backupTimeStamp
	Backup-SqlDatabase -ServerInstance $sqlInstance -Database $databaseName -BackupFile $bakFile
		
	cd $scriptPath
	# Backup the Octopus Data directory
	
	& "E:\Octopus\Octopus.Migrator.exe" export --instance "OctopusServer" --directory $octopusDataDirectory --password "Xceligent0508"
	
	#Zip contents of the newly created contents
	"Zipping $backupDirectory"
	$zipFile = "{0}\{1}-CompleteBackup.zip" -f $backupDirectoryRoot, $backupTimeStamp
	sz a "$zipFile" "$backupDirectory" -tzip
	
	remove-item $backupDirectory -recurse -force
	
	"Backup is ready: {0}" -f $zipFile
}

#-----------------------------------------------------------[Functions - Core]-----------------------------------------------------

function Main {
	#Begin primary code.
	$errorCode = 0
	try {
		OctopusBackup $backupDirectoryRoot
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
