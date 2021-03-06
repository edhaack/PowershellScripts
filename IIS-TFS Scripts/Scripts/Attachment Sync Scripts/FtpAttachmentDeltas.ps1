<#
PURPOSE: 

Second part: 
 1. Download: ListFile.txt (contains full path to files)
 2. For each file in the list, 
 		Replace "\\ftp\FTP2\Xceligent\Departments\IT\CDX-Attachments" w/ ""
		FTP all files in 'CDX-Attachments' directory
		Copy to XDWEBTEST P:\ApplicationImages_Prod\Attachments
 3. Remove all from FTP
 
This script should reside on XDWEBTEST (or the current CDX "TEST" Server for local copying of the latest Attachment uploads from prod.

CREATED: 2014.06.02 - ESH
UPDATED: 2014.06.25 - Using WinSCP to Xfer files 


#>
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)
$logFile = "$scriptName-$timeDateStamp.log"

cls
Start-Transcript -path $logFile -append

"
Script Start-Time: $startTime
"

# Set variables & constants

#ftp server
$ftpHost = "ftp.xceligent.com" 
$user = "CDX-Attachments" 
$pass = "Xceligent0508"
$fileListTxt = "FileList.txt"
$remotePath =  "/*"
$targetDirectory = "P:\ApplicationImages_Prod\Attachments"
$targetFile = "C:\Temp\$fileListTxt"
$cdxAttachmentsDir = "CDX-Attachments"

# BEGIN SCRIPT ===========================================
"ftp url: $ftpHost"

try
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
    try
    {
        # Connect
        $session.Open($sessionOptions)
 
        # Upload files
        $transferOptions = New-Object WinSCP.TransferOptions
        $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
		for($i=0;$i -le 999;$i++)
		{
			$currentDir = $i.ToString("000")
			$finalDir = "$targetDirectory\$currentDir\"
			Write-Host "Target: $finalDir"
			
			$session.GetFiles("/$currentDir/*", $finalDir, $True).Check()
		}
		
		for($i=0;$i -le 999;$i++)
		{
			$currentDir = $i.ToString("000")
			$finalDir = "$targetDirectory\rpt\$currentDir\"
			Write-Host "Target: $finalDir"
			
			$session.GetFiles("/rpt/$currentDir/*", $finalDir, $True).Check()
		}
		Write-Host "Download to $targetDirectory done."
    }
    finally
    {
        # Disconnect, clean up
        $session.Dispose()
    }
 
    exit 0
}
catch [Exception]
{
    Write-Host $_.Exception.Message
    exit 1
}


# END SCRIPT ===========================================

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
 
"
Complete at: $endTime
 
Duration:
{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours
 
Stop-Transcript
