<#
PURPOSE:
Copy latest uploaded media to AIR BC BCMON1 (FTP)

1. Read file on State1Retired: C:\x-copy\Log Files\state1_X\Images_[CurrentMonth]_[CurrentDay].txt
2. For each line in loaded file
2a. FTP file path to BCMon1's FTP Server
3. Complete.

CREATED:
2014.10.14 - ESH

UPDATED:


#>
# Set variables & constants
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)

$logFile = "$scriptName-$timeDateStamp.log"


$pathToXferLogs = "C:\x-copy\Log Files\state1_X\"
$logTodayTimeStamp = [DateTime]::Today.AddDays(-1).ToString('MM-dd')
$logYesterdayTimeStamp = [DateTime]::Today.AddDays(-1).ToString('MM-dd')  #Used for all log files, except "Images_"
#Images File uses yesterday for timestamp
$imagesLogFile = "Images_" + $logYesterdayTimeStamp + ".txt"
$imagesLogFullPath = $pathToXferLogs + $imagesLogFile

$ftp = "ftp://139.146.244.2/" 
$user = "xceligentIT" 
$pass = "itnKnpeV60V629AJWz4I"

$webclient = New-Object System.Net.WebClient 
$webclient.Credentials = New-Object System.Net.NetworkCredential($user,$pass) 


# BEGIN FUNCTIONS ===========================================
function ShowScriptBegin()
{
	cls
	#SStart-Transcript -path $logFile -append
	"
	Script Start-Time: $startTime
	=========================================
	"
}

function ShowScriptEnd()
{
	$endTime = Get-Date
	$elapsedTime = $endTime - $startTime
	"
	=========================================
	Complete at: $endTime

	Duration:
	{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours
	#Stop-Transcript
}

function CreateTempDir
{
   $tmpDir = [System.IO.Path]::GetTempPath()
   $tmpDir = [System.IO.Path]::Combine($tmpDir, [System.IO.Path]::GetRandomFileName())
   [System.IO.Directory]::CreateDirectory($tmpDir) | Out-Null
   $tmpDir
}

function TransferFile($filePath, $targetDir, $fileName)
{
	"Transferring: $filePath, $fileName"

	$ftpWithFile = "$ftp\$targetDir\$fileName"
	$ftpWithFile
	$uri = New-Object System.Uri($ftpWithFile) 
	try {
		$webclient.UploadFile($uri, $filePath) 
		
	}
	catch {
		throw $_
	}
}


# END FUNCTIONS ===========================================

# BEGIN SCRIPT ===========================================
ShowScriptBegin

#Load Image Log File...
$imagesLogFullPath
$reader = [System.IO.File]::OpenText($imagesLogFullPath)
try {
    for(;;) {
        $line = $reader.ReadLine()
        if ($line -eq $null) { break }
		if ($line.StartsWith("P:\")) { 
			#$line
			$fileName = $line.SubString($line.LastIndexOf("\")+1)
			$fileDir = $fileName.Substring(4, 3)

			TransferFile $line $fileDir $fileName
		}
		
        # process the line
        #$line
    }
}
finally {
    $reader.Close()
}

#Loop thru read file, get source path... Upload


ShowScriptEnd
# END SCRIPT ===========================================


