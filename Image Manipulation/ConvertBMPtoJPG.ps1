<#
CREATED: 2014.08.15 ESH

PARAMETERS:
	
EXAMPLE:
	
PURPOSE:

#>

#Script Parameters...
#param([string]$source = "C:", [string]$target = "C:")

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd)

$filePath = "C:\Comics\The Ninth Doctor Collected Comics"
$stringReplace = "bmp"
$stringReplaceWith = "gif"
$files = Get-ChildItem -Recurse -Path $filePath

#Load required assemblies and get object reference 
#[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms"); 
[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

foreach ($file in $files) { 
	if(!$file.name) { continue; }
	$fileName = $file.name
	$directory = $file.DirectoryName
	$fileDirectory = "$directory\$fileName"
	
	write-host "Original: $fileDirectory"
	
	$newFile = $fileName -replace $stringReplace, $stringReplaceWith
	write-host "New File: $directory\$newFile"
	
	$i = new-object System.Drawing.Bitmap($fileDirectory); 
	$i.Save("$directory\$newFile","GIF");	
	
    #Load required assemblies and get object reference
    #$convertfile = new-object System.Drawing.Bitmap($fileDirectory)
    #$convertfile.Save("$directory\$newFile", "jpeg")
    #$convertfile.Dispose()
}

