<#
FTP All SQL Bak's to BC Server: BCMon1
#>

$readyFile = "_SQLBAK_READY.txt"

function HandleException($exceptionObject){
    write-host "Caught an exception:" -ForegroundColor Red
    write-host "Exception Type: $($exceptionObject.Exception.GetType().FullName)" -ForegroundColor Red
    write-host "Exception Message: $($exceptionObject.Exception.Message)" -ForegroundColor Red
	
	
}

function TransferFiles($fullSourcePath, $targetDir ){
	#Delete Ready File
	if (Test-Path $fullSourcePath\$readyFile) { rm $fullSourcePath\$readyFile }
	
	#Main...
	try {
		#Transfer the files...
		. .\TransferFilesToBCMon1.ps1 $fullSourcePath $targetDir
		#Create Ready File
		ni $fullSourcePath\$readyFile -type file
	}
	catch {
		#Catch any exception thrown by the FTP... 
		HandleException $_
	}
}


#FTP All SQL BAKs
#TransferFiles "S:\AIR_BU_Files\SQLM01PROD" "SQLM01PROD"

#TransferFiles "S:\AIR_BU_Files\SQLM02PROD" "SQLM02PROD"

#TransferFiles "S:\AIR_BU_Files\XPVSQLM01" "XPVSQLM01"

TransferFiles "S:\AIR_BU_Files\XPVSQLM01" "BOGUS"

