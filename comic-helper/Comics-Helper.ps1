#!/usr/bin/pwsh
#Requires -Version 7

<# Comments
.SYNOPSIS
    Given a list of things
    Then do something with it

.NOTES
	16 Oct 2020 : Ed Haack : Initial Development
#>

[CmdletBinding()]
param (
	[Parameter()]
	[String] $Script:ComicsPath = "C:\TheGreenDome_L_Downloads\Downloads"
)

Process {
	Assert-Parameters # Check / Massage Values

	if ($Script:ShouldInvokeMainProcess) {
		Invoke-MainProcess	# Primary Operations
	}

	if ($Script:ShouldPublishArtifacts) {
		Publish-Artifacts	# Final - create results
	}
}

Begin {
	#region Script Variables
	[Bool] $Script:ShouldInvokeMainProcess = $false
	[Bool] $Script:ShouldPublishArtifacts = $false
	[String] $Script:WorkingDir = $PSScriptRoot
	#endregion

	#region Process Methods
	function Assert-Parameters() {
		$Script:ShouldInvokeMainProcess = $true
	}

	function Invoke-MainProcess() {

		#get all comics files
		$dcDirectoryList = Get-ChildItem $Script:ComicsPath -Filter "DC Week*"
		$dcDirectoryList | % {
			"Working on: {0}" -f $_
			Push-Location $_
			[String] $dirName = Split-Path $_ -Leaf
			$itemDate = $dirName.Substring( $dirName.IndexOf("(") + 1, 10 )
			$itemDate = Get-Date $itemDate
			# $itemDate = "{0}.{1}" -f $itemDate.Year, $itemDate.Month
			$itemDate = $itemDate.ToString("yyyy.MM")

			if (!( Test-Path "Done.txt" )) {
				$comicsItemList = Get-ChildItem *.cbr, *.cbz
				$comicsItemList | % {
					[String] $fileName = $_.Name
					[String] $ext = $_.Extension

					"Comic Filename: {0}" -f $fileName
					$rawTitle = $fileName.Substring(0, $fileName.IndexOf("("))
					$issueNumber = $rawTitle -replace "\D", ""
					$issueNumber

					$title = ($rawTitle -replace $issueNumber, "").Trim()

					$newFilename = "{0}.{2}.{3}{1}" -f $title, $ext, $itemDate, $issueNumber
					$newFilename
					"Renaming: '{0}' to '{1}'" -f $fileName, $newFilename
					Move-Item $fileName $newFilename
					"Done" > Done.txt
				}
			}
			else {
				"Already Done: {0}" -f $dirName
			}
			#Now that we have the proper filename convention
			#Loop thru each DC week, and move the item title to a new, title-based directory in Downloads

			$targetBasePath = Join-Path $Script:ComicsPath "DC Comics"
			$comicsItemList = Get-ChildItem *.cbr, *.cbz
			$comicsItemList | % {
				[String] $fileName = $_.Name
				$fileName
				[String] $mvTitle,$mvYear,$mvMonth,$mvIssueNumber,$vmExt = $fileName.Split(".")
				$targetPath = Join-Path $targetBasePath $mvTitle
				"Target Path: {0}" -f $targetPath
				if(!( Test-Path $targetPath )) { mkdir $targetPath }

				"Moving: {0} to {1}" -f $fileName, $targetPath
				Move-Item $fileName $targetPath

			}

			Pop-Location
		}


		$Script:ShouldPublishArtifacts = $true
	}

	function Publish-Artifacts() {

	}
	#endregion

	#region Private Methods

	#endregion
}

# end of line.
