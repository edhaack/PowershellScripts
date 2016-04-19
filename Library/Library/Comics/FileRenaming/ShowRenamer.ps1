##### Show File Renamer - Replace 

Param($filePath='C:\comics', $stringReplace='', $stringReplaceWith='')

$files = Get-ChildItem -Recurse -Path $filePath

foreach ($file in $files) { 
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
	