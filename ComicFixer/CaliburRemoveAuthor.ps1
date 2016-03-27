##### Comic File Renamer - Replace 

Param($filePath='C:\comics', $authorName='')

$ext = ".mobi"
$caliburAuthor = " - $authorName"
$comicFiles = Get-ChildItem -Recurse -Path $filePath

foreach ($file in $comicFiles) { 
	if(!$file.name) { continue; }
	$fileName = $file.name
	if(!$fileName.Contains($ext)) { continue;}
	
	#$newFileName = $fileName.SubString(0,($fileName.LastIndexOf($caliburAuthor))) 
	#$newFileName = $newFileName + $ext
	$newFileName = $fileName.Replace(" .mobi", $ext)
	
	write-host "New Filename: $newFileName"
	
	$directory = $file.DirectoryName
	$fileDirectory = "$directory\$fileName"

	Rename-Item -Force "$fileDirectory" "$directory\$newFileName"
}