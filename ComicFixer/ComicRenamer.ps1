##### Comic File Renamer - Replace 

Param($filePath='C:\comics', $stringReplace='', $stringReplaceWith='')

$comicFiles = Get-ChildItem -Recurse -Path $filePath

foreach ($file in $comicFiles) { 
	if(!$file.name) { continue; }
	$fileName = $file.name
	$directory = $file.DirectoryName
	$fileDirectory = "$directory\$fileName"
	write-host "Filename: $fileDirectory"
	
	#$newFile = $fileName -replace $stringReplace, $stringReplaceWith
	$newFile = $fileName.Replace($stringReplace, $stringReplaceWith)
	write-host "New File: $directory\$newFile"
	
	Rename-Item -Force "$fileDirectory" "$directory\$newFile"
}
	