<#
Purpose: Take FTP'd zip roll package, extract to 'rollout' dir and xcopy sites/services to web.
Created: 2014.02.10 ESH

This is the second part of a Demo Deployment Process. The first part created the zip roll package from the Test Server(s)
#>

<#  --VARIABLES BEGIN-- #>

set-alias sz "C:\Program Files\7-Zip\7z.exe" 
$startTime = Get-Date
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#directories/locations
#$deploymentDir = "D:\Deployment"
$deploymentDir = "D:\testing"
$rolloutDir = $deploymentDir + "\Rollout"
$rolloutOldDir = $deploymentDir + "\Rollout_OLD"

$rollPackageLocation = "\\ftp\FTP\Vendor\Acxiom"
$rollPackageFilename = "ProdBuild.zip"
$rollPackageFullSource = $rollPackageLocation + "\" + $rollPackageFilename
$rollPackageFullDestination = $deploymentDir + "\" + $rollPackageFilename

<# -- VARIABLES END -- #>



<# -- SCRIPT BEGIN -- #>

"
Begin the procedures to build roll package to Test Environment: $startTime
 Steps in this script:
	1) Copy uploaded roll package (ProdBuild.zip) to working directory
	2) Remove Rollout_OLD directory
	3) Move Rollout directory to Rollout_OLD
	4) Extract roll-package to Rollout directory
	5) Ready for MaxCopy operations.
 
"


# Delete existing D:\Deployment\ProdBuild.zip
if(Test-Path $rollPackageFullDestination){ 
	"Deleting old build package from: $rollPackageFullDestination
	"
	Remove-Item -Force $rollPackageFullDestination
}

# Copy uploaded zip package to D:\Deployment
Copy-Item $rollPackageFullSource $rollPackageFullDestination

#new roll package now local.

# Delete existing D:\Deployment\Rollout_OLD
if(Test-Path $rolloutOldDir){ 
	"Deleting old build package from: $rolloutOldDir
	"
	Remove-Item -Recurse -Force $rolloutOldDir
}


if(Test-Path $rolloutDir) {
"
Moving Rollout files to the Rollout_OLD directory...

"
	# Move-Item doesn't work here b/c permissions... 
	Copy-Item -Recurse -Force $rolloutDir $rolloutOldDir
	Remove-Item -Recurse -Force $rolloutDir
}

"Creating $rolloutDir
"
New-Item -ItemType Directory -Force -Path $rolloutDir

# Extract zip to Rollout
sz x "-o$rolloutDir" $rollPackageFullDestination

# ProdBuild, move Production & Config dirs up one level...
Move-Item $rolloutDir"\ProdBuild\Production" $rolloutDir"\Production"
Move-Item $rolloutDir"\ProdBuild\The Build Config Files" $rolloutDir"\The Build Config Files"
Remove-Item -Force $rolloutDir"\ProdBuild"


# XCopy extracted files/dirs to destinations.

# This part is what MaxCopy does...


# finish

$endTime = Get-Date

$elapsedTime = $endTime - $startTime

"
Duration:
{0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds
"

Files are ready for MaxCopy execution.
"


<# -- SCRIPT END -- #>

