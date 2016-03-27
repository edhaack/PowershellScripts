
$filePath = "I:\Calibre Library\John Broome\Orig Lantern" 
$bak = Get-ChildItem -Recurse -Path $filePath | Where-Object { $_.Extension -eq ".orig" } 
 
 
foreach ($file in $bak) { 
                    $name = $file.name 
					"Filename: $name"
					" "
					$newName = $name.Replace(".orig", ".cbr")
					"New Name: $newName"
					" "
					
					$directory = $file.DirectoryName 
					"Directory: $directory"
					cd "$directory"
					
					Rename-Item -Force "$name" "$newName"
					"Complete"
					" "
                } 