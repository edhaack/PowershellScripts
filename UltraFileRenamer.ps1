<#
Need: 
	Send episode name with ## as wildcards representing the episode number(s)

Action:
- set vars for proper episode naming (e.g. S##E##)
- Loop thru each file in directory
- verify that the search string exists within the current filename
- get ## value
- 

#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$filePath,
	
   [Parameter(Mandatory=$True)]
   [string]$showSeason,
   
   [Parameter(Mandatory=$True)]
   [string]$showName
)

$currentDir = $MyInvocation.MyCommand.Path
$files = Get-ChildItem -Recurse -Path $currentDir


foreach ($file in $files) { 
	if(!$file.name) { continue; }
	$fileName = $file.name
	if(!$fileName.Contains($searchKeyword)) { continue;}
	
	$newFileName = $fileName.Replace($searchKeyword, '')
	
	write-host "New Filename: $newFileName"
	
	$directory = $file.DirectoryName
	$fileDirectory = "$directory\$fileName"

	Rename-Item -Force "$fileDirectory" "$directory\$newFileName"
}