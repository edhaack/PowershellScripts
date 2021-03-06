<#
PURPOSE:
FTP (Using WinSCP) Upload multiple files to a destination server.

CREATED:
2014.10.23 - ESH

UPDATED:

NOTES: Using WinSCP Library b/c both (System.Net) WebClient and FtpWebRequest are good at one-off file uploading, but not multiple files & directories.
WinSCP has proven to be superior in this regard.

#>

# Set variables & constants
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)
$logFile = "$scriptName-$timeDateStamp.log"

$pathToXferLogs = "C:\x-copy\Log Files\state1_X\"
#$pathToXferLogs = "C:\Temp\"

$logTodayTimeStamp = [DateTime]::Today.AddDays(-1).ToString('MM-dd')
$logYesterdayTimeStamp = [DateTime]::Today.AddDays(-1).ToString('MM-dd')  #Used for all log files, except "Images_"
#Images File uses yesterday for timestamp
$imagesLogFile = "Images_" + $logYesterdayTimeStamp + ".txt"
$imagesLogFullPath = $pathToXferLogs + $imagesLogFile

$ftp = "ftp://139.146.244.2/" 
$ftpHost = "139.146.244.2"
$user = "xceligentIT" 
$pass = "itnKnpeV60V629AJWz4I"

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
	Complete at: $endTime

	Duration:
	{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours
	Stop-Transcript
	Exit
}

function BeginFtpSession()
{
    # Load WinSCP .NET assembly
    Add-Type -Path "$scriptPath/WinSCPnet.dll"
 
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions
    $sessionOptions.Protocol = [WinSCP.Protocol]::Ftp
    $sessionOptions.HostName = $ftpHost
    $sessionOptions.UserName = $user
    $sessionOptions.Password = $pass
 
    $session = New-Object WinSCP.Session
	# Connect
	$session.Open($sessionOptions)

	return $session
}

function EndFtpSession()
{
	$session.Dispose()
}

function TransferFile($sourceFilePath, $fileName)
{
	"Executing: TransferFile"

	$targetFtpDir = GetFtpTargetDir $fileName
	
	try {
		"Source: $sourceFilePath
		Target: $targetFtpDir"
		#$transferResult = $session.PutFiles("b:\toupload\*", "/home/user/", $False, $transferOptions)
		$transferResult = $ftpSession.PutFiles($sourceFilePath, $targetFtpDir, $False, $transferOptions)
	}
	catch {
		throw $_
	}
}

function GetFtpTargetDir($filename)
{
	$pathForAttachments = "State1/Attachments/"
	$targetDir = $fileName.Substring(4, 3) #This is the Attachment Numbered Directory
	$rptDir = "rpt/"
	if ($fileName -like "*_rpt.*")
	{
		$ftpWithFile = "$pathForAttachments$rptDir$targetDir/$fileName"
	}
	else
	{
		$ftpWithFile = "$pathForAttachments$targetDir/$fileName"
	}
	return $ftpWithFile
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
	Write-Host "Sending email to: $emailTo"
	
	$emailMessage = New-Object System.Net.Mail.MailMessage( $emailFrom , $emailTo )
	$emailMessage.Subject = "AIR BC Daily: Failure to FTP Media"
	$emailMessage.IsBodyHtml = $false
	$emailMessage.Body = $errorMessage

	$SMTPClient = New-Object System.Net.Mail.SmtpClient( $smtpServer )
	$SMTPClient.Send( $emailMessage )
}

# END FUNCTIONS ===========================================

# BEGIN SCRIPT ===========================================
ShowScriptBegin

#Load Image Log File...
Write-Host "Loading Log file: $imagesLogFullPath"
if (!(Test-Path $imagesLogFullPath))
{
	Write-Host "Missing Log File: $imagesLogFullPath"
	ShowScriptEnd
}

#Establish FTP Connection (rather than a connection per file, that would be nuts!)
$ftpSession = BeginFtpSession
$transferOptions = New-Object WinSCP.TransferOptions
$transferOptions.TransferMode = [WinSCP.TransferMode]::Binary

$reader = [System.IO.File]::OpenText($imagesLogFullPath)
try {
    for(;;) {
        $line = $reader.ReadLine()
        if ($line -eq $null) { break }
		if ($line -like "*CDXMail*") { continue }
		if ($line -like "*BranchImages*") { continue }
		if ($line -like "*\Attachments\*")
		{
			$fileName = $line.SubString($line.LastIndexOf("\")+1)
			TransferFile $line $fileName
		}
    }
}
catch {
	HandleException $_ 
}
finally {
    $reader.Close()
}

EndFtpSession

ShowScriptEnd
# END SCRIPT ===========================================

  
