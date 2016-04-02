<#
===========================================================================
PURPOSE: Comic Book Image Down-sizer

OVERVIEW:
1) Get directory where comics are to be down-sized
2) For each .cbz, 
	2a) extract to temporary directory
	2b) For each image in extracted directory, Resize with 'ResizerOfPictures' ps1
	2c) 7Zip resized images to new filename "-tablet.cbz"
	2d) Delete temporary directory
	
CREATED:
1.0 4/20/2015 - ESH - Initial release
1.1 4/21/2015 - ESH - Check if current file is already -tablet and continue
1.2 9/26/2015 - check for poster's file... "z.jpg" etc. -- via an array of known files...
	- Files less than 100kb are removed from the temp directory, prior to processing for tablet version
	- also, commented out the logging and 'press any key' bullshit
	- and found it usefull to return to the scriptDir for other comic dirs...

UPDATED:
===========================================================================
#>


# BEGIN Parameters ===========================================
Param (
	[Parameter(Mandatory=$True)]
	[ValidateNotNull()]
	[string] $DirectoryPath
)

# END Parameters ===========================================

# BEGIN VARIABLES ===========================================
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)
$logFile = "$scriptName-$timeDateStamp.log"
$tempDirName = "temp"
$resizerOfPictures = "$scriptPath\ResizerOfPictures.ps1"

set-alias sz "$scriptPath\7z.exe"

# BEGIN FUNCTIONS ===========================================
function Main() {
	Write-Host  "Getting contents of directory: $DirectoryPath"

	$comicsDirectory = Get-ChildItem -Recurse -Path $DirectoryPath | Where-Object { $_.Extension -eq ".cbz" -or $_.Extension -eq ".cbr" } 

	foreach ($file in $comicsDirectory) { 
		$name = $file.name
		$baseFilename = $file.basename
		$cbzFile = "{0}-tablet.cbz" -f $baseFilename
		$fullTargetPath = "{0}\{1}" -f $DirectoryPath, $cbzFile
		$directory = $file.DirectoryName 
		$tempDirectory = "$directory\$tempDirName"

		#Check if current file is already tablet ready, or one that already has been...
		if ($name.Contains("-tablet")) { continue }
		if (Test-Path $fullTargetPath ) { continue }
		
		"Working with file: $name"
		
		if (Test-Path $tempDirectory) {
			Remove-Item -Force -Recurse $tempDirectory
		}
		
		mkdir $tempDirectory
		cd $tempDirectory
		
		"Extracting: $tempDirectory\$name"
		sz e "$directory\$name" -aoa
		
		RemoveNonComicFiles 
		
		"Invoking ResizerOfPictures..."
		Invoke-Expression "& `"$resizerOfPictures`" '$tempDirectory'"
		
		"Zipping $tempDirectory"
		sz a "$directory\$cbzFile" "$tempDirectory\*.jpg" -tzip
		
		cd $directory
		
		Remove-Item $tempDirectory\* -recurse -Force
		
		Start-Sleep -Seconds 5
	}
	
	CleanUpOldFiles
	
	#Go back to the scriptPath directory
	cd $scriptPath
}

function RemoveNonComicFiles(){
	"Removing files that are in the original archive that are less than 100k"
	
	#Already in the 'temp' directory, need to remove files that are below 100k, and that are in the array set at the top.
	
	#Remove the files less than 100kb.
	#Note: This may not be the best of ideas... but it will work 99% of the time.
	gci . | ? {$_.length -lt 100000} | % {Remove-Item $_.fullname}
	
	#Most of the other non-comic files (.nfo, .sfv, and 'z.jpg') are typically removed via the above (less than 100kb)
	#Ran into a comic with a custom file that was larger than 100kb... Need to start the array :(
	$filesToDelete = @("MM-Y2K", "XXX", "Thumbs.db", "zzz", "SCTeam2", "z_", "tag_mm")
	$tempDirectory = gci .
	foreach ($file in $tempDirectory) {
		$fileName = $file.fullname
		foreach ($test in $filesToDelete) {
			$testFilename = $fileName.ToLower()
			$testString = $test.ToLower()
			#Test if current file matches any content within the array of files to delete
			if($testFilename.indexOf($testString) > -1) {
				DeleteFile($fileName)
			}
		}
		#Maybe not in the array, but if the file starts with a "z" then most likely it's bonk! kill it
		$baseName = $file.BaseName.toLower()
		if ($baseName.startsWith("z")){
			DeleteFile($fileName)
		}
	}
}

function DeleteFile($fileName){
	#Found one, delete it!
	"Removing: $fileName"
	Remove-Item $fileName	
}

function CleanUpOldFiles(){
	"Cleaning up files logs and backups"
	gci $scriptPath | where{-not $_.PsIsContainer -and $_.Extension -eq ".log"}| sort CreationTime -desc| select -Skip 5| Remove-Item -Force
}

function ShowScriptBegin() {
	cls
	#Start-Transcript -path $logFile -append
	"
	Script Start-Time: $startTime
	"
}

#Used for script testing/debugging
function PauseScript() {
	Write-Host "Press any key to continue ..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function ShowScriptEnd() {
	$endTime = Get-Date
	$elapsedTime = $endTime - $startTime
	"
	Complete at: $endTime

	Duration:
	{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours
	#Stop-Transcript
	
	#Write-Host "Press any key to continue ..."
	#$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

}
# END FUNCTIONS ===========================================

# BEGIN SCRIPT ===========================================
ShowScriptBegin

Main

ShowScriptEnd
# END SCRIPT ===========================================
