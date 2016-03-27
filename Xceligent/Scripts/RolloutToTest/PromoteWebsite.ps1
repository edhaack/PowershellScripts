<#
Script to get latest, filter out source-related files and copy to destination.
2014.02.28 ESH
#>

<#  --VARIABLES BEGIN-- #>
$sourceDir = $args[0]
$destinationDir = $args[1]
$specficWebConfig = $args[2]

$excludeExts = @("config", "sln", "metaproj", "vspscc", "resx", "tmp", "vb", "vbproj", "cs", "csproj", "resx", "pdb", "bak", "user", "suo", "vssscc")
$excludeDirs = @("obj", "RadControls", "Service References", "Web References", "My Project")

<#  --VARIABLES END-- #>

Write-Host "Source Path: $sourceDir"
Write-Host "Destination Path: $destinationDir"

<# Remove unnecessary files by extension from source.#>
for ($i=0; $i -lt $excludeDirs.length; $i++) {
	$currentDir = "\" + $excludeDirs[$i]
	$finalDir = $sourceDir + $currentDir
	if(Test-Path $finalDir) { Remove-Item -Recurse -Force $finalDir }
}

<# Remove unnecessary files by extension from source. #>
for ($i=0; $i -lt $excludeExts.length; $i++) {
	$current = "*." + $excludeExts[$i]
	get-childitem $sourceDir -include $current -recurse | foreach ($_) {remove-item $_.fullname -force}
}

<# Update Proper Web.config #>
if($specficWebConfig) {
	$finalWebConfig = $sourceDir + "\web.config"
	Copy-Item $specficWebConfig $finalWebConfig 
}

<# Copy files from source to destination (aka: The Beef #>
Copy-Item $sourceDir\* $destinationDir -recurse -force

<#  --SCRIPT END-- #>
