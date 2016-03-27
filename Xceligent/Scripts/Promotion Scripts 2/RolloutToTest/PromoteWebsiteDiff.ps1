
function PromoteWebsiteDiff($source, $target){
	$Path1 = $source
	$Path2 = $target
	$OutFile = "C:\ComparisonOutputFile.txt"
	
	Write-Host "
	Source: $Path1
	Target: $Path2
	Output File: $OutFile
	
	"

	# Delete outfile if it exists
	If (Test-Path($OutFile)) {Remove-Item $OutFile}

	#New Files...
	<#"Getting new files"
	$newFiles = Compare-Object (gci $Path1 -Recurse) (gci $Path2 -Recurse) | where {$_.SideIndicator -eq "<="} 
	
	ForEach ($newFile in $newFiles) {
		$newFile.InputObject.fullname | Out-File $OutFile -Append
	}
#>

	#Get files that exist in both dir's, but are different...

	# Write the two paths to the outfile so you know what you’re looking at
	#"Differences in files of the same name between the following folders:" | Out-File $OutFile -append $Path1 + " AND " + $Path2 | Out-File $OutFile

	 # Compare two folders and return only files that are in each
	$Dir1 = Get-ChildItem -Path $Path1 -Recurse
	$Dir2 = Get-ChildItem -Path $Path2 -Recurse
	
	
	#$FileList = Compare-Object $Dir1 $Dir2 -IncludeEqual -ExcludeDifferent

	"Comparing src to target...
	
	"
	#Compare files that are the same between the two directories, so that each file can be compared.
	$FileList = Compare-Object $Dir1 $Dir2 -IncludeEqual
	"--------" | Out-File $OutFile -Append
	# Loop the file list and compare file contents
	ForEach ($File in $FileList)
	{
		$F1 = $Path1 + "\" + $File.InputObject
		$F2 = $Path2 + "\" + $File.InputObject
		#$File.InputObject.name
		"		
		=================
		Current Files:
			$F1
			$F2
		=================
		"
		return
		#ignore if current item is a directory...
		if(Test-Path $F1 -PathType Container) { continue }
		
		Write-Host "Looking for $F1  & $F2"
		#Verified that both files exist
		if(!(Test-Path $F1)) { continue }
		if(!(Test-Path $F2)) { continue }
		
		"
		=================
		Both files exist and is not a directory...
		===================
		"
		$diff = Compare-Object -ReferenceObject $(Get-Content $F1) -DifferenceObject $(Get-Content $F2)
		if($diff){
			$F1 | Out-File $OutFile -Append
		}
	}
}

PromoteWebsiteDiff "C:\Temp\xceligentApp" "\\XDWEBTEST\devroot\xceligentApp"