#### 7 zip variable I got it from the below link  
 
#### http://mats.gardstad.se/matscodemix/2009/02/05/calling-7-zip-from-powershell/  
# Alias for 7-zip 
#if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {throw "$env:ProgramFiles\7-Zip\7z.exe needed"} 
#set-alias sz "$env:ProgramFiles\7-Zip\7z.exe" 

set-alias sz "C:\Program Files\7-Zip\7z.exe" 
 
############################################ 
#### Variables  
 
$filePath = "F:\Comics\DC\Superman's Girlfriend Lois Lane" 
 
$bak = Get-ChildItem -Recurse -Path $filePath | Where-Object { $_.Extension -eq ".cbr" } 
 
########### END of VARABLES ################## 
 
foreach ($file in $bak) { 
                    $name = $file.name 
					"Filename: $name"
                    $directory = $file.DirectoryName 
					"Directory: $directory"
					$tempFile = $name.Replace(".cbr",".cbr.orig")
					$cbrFile = $file.name
					$cbzFile = $cbrFile.Replace(".cbr", ".cbz")
					
					cd $directory
					Remove-Item -Force -Recurse "temp"
					mkdir "temp"
					cd temp
					$tempDirectory = "$directory\temp"
                    sz e "$directory\$name" -aoa
					
					"Renaming: $directory\$name $directory\$tempFile"
					Rename-Item -Force "$directory\$name" "$directory\$tempFile"
					sz a "$directory\$cbzFile" "$tempDirectory\*.jpg" -tzip
					cd "$filePath"
					Remove-Item -Force -Recurse "$tempDirectory"
                } 
 
########### END OF SCRIPT ########## 