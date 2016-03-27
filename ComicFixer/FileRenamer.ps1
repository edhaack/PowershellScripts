##### Comic File Renamer - Replace 

Param($filePath='J:\temp', $prefix=' (2015) (Digital-Empire)-')

$ext = ".mobi"
$comicFiles = Get-ChildItem -Recurse -Path $filePath

foreach ($file in $comicFiles) { 
	if(!$file.name) { continue; }
	$fileName = $file.name
	if(!$fileName.Contains($ext)) { continue;}
	
	$newFileName = $fileName.Replace($prefix, '')
	
	write-host "New Filename: $newFileName"
	
	$directory = $file.DirectoryName
	$fileDirectory = "$directory\$fileName"

	Rename-Item -Force "$fileDirectory" "$directory\$newFileName"
}