/*
1. QuickPar Fix
2. Extract File
3. Clean-up downloaded Files
4. Move to designated directory

Notepad++: NPP_Exec command:
NPP_Save
cmd /c echo. |Powershell -nologo '$(FULL_CURRENT_PATH)'

  par2 verify test.mpg.par2
  
*/

$filePath = "C:\DownloadsTest"
"File path: $filePath"

set-alias par "C:\apps\par2.exe" 

#Loop thru dir, find first par file in dir, verify, repair if needed.
$files = Get-ChildItem -Recurse -Path $filePath | Where-Object { $_.Extension -eq ".par2" } 
Write-Verbose "File: ..."
foreach ($file in $files) { 
	$name = $file.name 
	"Filename: $name"
	if($name.Contains("sample") ) continue
	
	
	$directory = $file.DirectoryName 
	"Directory: $directory"

}

#par verify 
