#requires -version 2
<#
.SYNOPSIS
  ScheduledBackup.ps1

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

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#-----------------------------------------------------------[Functions - Script Specific]------------------------------------------
function Execute-HTTPPostCommand() {
    param(
        [string] $url,
        [string] $username,
        [string] $password
    )

    $authInfo = $username + ":" + $password
    $authInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::Default.GetBytes($authInfo))

    $webRequest = [System.Net.WebRequest]::Create($url)
    $webRequest.ContentType = "text/html"
    $PostStr = [System.Text.Encoding]::Default.GetBytes("")
    $webrequest.ContentLength = $PostStr.Length
    $webRequest.Headers["Authorization"] = "Basic " + $authInfo
    $webRequest.PreAuthenticate = $true
    $webRequest.Method = "POST"

    $requestStream = $webRequest.GetRequestStream()
    $requestStream.Write($PostStr, 0, $PostStr.length)
    $requestStream.Close()

    [System.Net.WebResponse] $resp = $webRequest.GetResponse();
    $rs = $resp.GetResponseStream();
    [System.IO.StreamReader] $sr = New-Object System.IO.StreamReader -argumentList $rs;
    [string] $results = $sr.ReadToEnd();

    return $results;
}

function Execute-TeamCityBackup() {
    param(
        [string] $server,
        [string] $addTimestamp,
        [string] $includeConfigs,
        [string] $includeDatabase,
        [string] $includeBuildLogs,
        [string] $includePersonalChanges,
        [string] $fileName
    )
    $TeamCityURL = [System.String]::Format("{0}/httpAuth/app/rest/server/backup?addTimestamp={1}&includeConfigs={2}&includeDatabase={3}&includeBuildLogs={4}&includePersonalChanges={5}&fileName={6}",
                                            $server,
                                            $addTimestamp,
                                            $includeConfigs,
                                            $includeDatabase,
                                            $includeBuildLogs,
                                            $includePersonalChanges,
                                            $fileName);

    Execute-HTTPPostCommand $TeamCityURL "admin" "Xceligent0508"
}


#-----------------------------------------------------------[Functions - Core]-----------------------------------------------------

function Main {
	#Begin primary code.
	$errorCode = 0
	try {
		$server = "http://teamcity.xceligent.org:8181"
		$addTimestamp = $true
		$includeConfigs = $true
		$includeDatabase = $true
		$includeBuildLogs = $true
		$includePersonalChanges = $true
		$fileName = "TeamCity_Backup_"

		Execute-TeamCityBackup $server $addTimestamp $includeConfigs $includeDatabase $includeBuildLogs $includePersonalChanges $fileName
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
