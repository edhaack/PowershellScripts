<#  --VARIABLES BEGIN-- #>
$sourceDir = $args[0]
$destinationDir = $args[1]

$excludeExts = @("config", "sln", "metaproj", "vspscc", "resx", "tmp", "vb", "vbproj", "cs", "csproj", "resx", "pdb", "bak", "user", "suo", "vssscc")
$excludeDirs = @("obj", "RadControls", "Service References", "Web References", "My Project")

<#  --VARIABLES END-- #>

Write-Host "Source Path: $sourceDir"
Write-Host "Destination Path: $destinationDir"

<# Remove unnecessary files by extension from source.#>
for ($i=0; $i -lt $excludeDirs.length; $i++) {
	$currentDir = "\" + $excludeDirs[$i]
	$finalDir = $sourceDir + $currentDir
	Write-Host "Removing Dir: $finalDir"
	Remove-Item -Recurse -Force $finalDir
}

<# Remove unnecessary files by extension from source. #>
for ($i=0; $i -lt $excludeExts.length; $i++) {
	$current = "*." + $excludeExts[$i]
	Write-Host "Removing Ext: $current"
	get-childitem $sourceDir -include $current -recurse | foreach ($_) {remove-item $_.fullname -force}
}




<#  --SCRIPT END-- #>
