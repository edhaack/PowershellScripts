<#
Script to get latest, filter out source-related files and copy to destination.
2014.02.28 ESH
#>

<#  --VARIABLES BEGIN-- #>
$sourceDir = $args[0]
$destinationDir = $args[1]
$webConfig = $args[2] #This argument repurposed for Target Environment.

$excludeExts = @("config", "sln", "metaproj", "vspscc", "resx", "tmp", "vb", "vbproj", "cs", "csproj", "resx", "pdb", "bak", "user", "suo", "vssscc", "vspscc")
$excludeFiles = @("thumbs.db")
$excludeDirs = @("obj", "RadControls", "Service References", "Web References", "My Project")

<#  --VARIABLES END-- #>

Write-Host "Source Path: $sourceDir"
Write-Host "Destination Path: $destinationDir"

<# Remove unnecessary directories from source.#>
for ($i=0; $i -lt $excludeDirs.length; $i++) {
	$currentDir = "\" + $excludeDirs[$i]
	$finalDir = $sourceDir + $currentDir
	if(Test-Path $finalDir) { Remove-Item -Recurse -Force $finalDir }
}

<# Remove selected files #>
for ($i=0;i -lt $excludeFiles.lenth; $i++) {
	$current = $excludeFiles[$i]
	Get-ChildItem $sourceDir -Include $current -Recurse | foreach ($_) {Remove-Item $_.fullname -Force)
}

<# Remove unnecessary files by extension from source. #>
for ($i=0; $i -lt $excludeExts.length; $i++) {
	$current = "*." + $excludeExts[$i]
	get-childitem $sourceDir -include $current -recurse | foreach ($_) {remove-item $_.fullname -force}
}

<# Update Proper Web.config, if specified #>
if($webConfig) {
	$finalWebConfig = $sourceDir + "\web.config"
	Copy-Item $webConfig $finalWebConfig 
}

<# Copy files from source to destination (aka: The Beef #>
Copy-Item $sourceDir\* $destinationDir -recurse -force

<#  --SCRIPT END-- #>
