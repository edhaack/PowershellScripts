#### http://mats.gardstad.se/matscodemix/2009/02/05/calling-7-zip-from-powershell/  
# Alias for 7-zip 
Param($filePath='C:\comics', $ext='.zip', $title='', $fileNameRemove='', [switch] $useIssueNumber)
Write-Host "Loading... " $filePath
write-host "useIssueNumber: $useIssueNumber"

set-alias sz "C:\Program Files\7-Zip\7z.exe" 
 
$bak = Get-ChildItem -Recurse -Path $filePath | Where-Object { $_.Extension -eq $ext } 

########### END of VARABLES ################## 
 
foreach ($file in $bak) { 
	if(!$file.name) { continue; }
	
	$name = $file.name 
	write-host $name
	
	if($useIssueNumber){
	#Regex to get only the issue number
	$issueNumber = $name -replace "[^0-9]", '' 
	write-host $issueNumber
	}
	
	"Filename: $name"
	$directory = $file.DirectoryName 
	"Directory: $directory"
	
	$tempFile = ("{0}.orig" -f $name)
	$cbzFile = ("{0}.cbz" -f ($name -replace $ext, ""))
	if($useIssueNumber)
	{
		$cbzFile = ("{0}.{1}.cbz" -f $title, $issueNumber)
	}
	else
	{
		if($title -ne "")
		{
			$cbzFile = ("{0}.cbz" -f $title)
		}
	}
	
	#Remove part of filename... e.g. " v2 "
	if($fileNameRemove -ne ""){
		$cbzFile = $cbzFile -replace $fileNameRemove, ""
	}
	
	cd $directory
	Remove-Item -Force -Recurse "temp"
	mkdir "temp"
	cd temp
	$tempDirectory = "$directory\temp"
	
	"Extracting: $directory\$name"
	sz e "$directory\$name" -aoa
	
	"Renaming: $directory\$name $directory\$tempFile"
	Rename-Item -Force "$directory\$name" "$directory\$tempFile"
	
	"Zipping $directory\$cbzFile"
	sz a "$directory\$cbzFile" "$tempDirectory\*.jpg" -tzip
	cd "$filePath"
	Remove-Item -Force -Recurse "$tempDirectory"
} 
 
########### END OF SCRIPT ########## 