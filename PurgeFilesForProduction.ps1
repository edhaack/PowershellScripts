
#Remove Dirs/Files Source, other not needed in production
$sourceDir = "D:\Inetpub\Production"

$excludeExts = @("scc", "sln", "metaproj", "vspscc", "resx", "tmp", "vb", "vbproj", "cs", "csproj", "resx", "pdb", "bak", "user", "suo", "vssscc")
$excludeDirs = @("obj", "RadControls", "Service References", "Web References", "My Project", ".svn", "Pants", "_vti_cnf")

for ($i=0; $i -lt $excludeDirs.length; $i++) {
	$currentDir = $excludeDirs[$i]
	Write-Host "Removing Directories: $currentDir" 
	Get-ChildItem -path $sourceDir -Include $currentDir -Recurse -force | Remove-Item -force -Recurse
}

for ($i=0; $i -lt $excludeExts.length; $i++) {
	$current = "*." + $excludeExts[$i]
	Write-Host "Removing Files: $current" 
	get-childitem $sourceDir -include $current -recurse | foreach ($_) {remove-item $_.fullname -recurse }
}
