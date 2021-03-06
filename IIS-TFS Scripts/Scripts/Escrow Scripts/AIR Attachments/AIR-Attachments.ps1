<#
Created: 2014.03.24 ESH
Updated: 2014.03.26 ESH - Adding Progress and other useful info

PARAMETERS:
source
	- The root source drive where the attachments are.
target
	- The root destination drive where the attachments are to be copied.
	
EXAMPLE:
.\AIR-Attachments.ps1 -source C:\Source -target C:\Target
	

PURPOSE:
Gets all of the AIR Attachment files and will copy to target, w/ time-date stamp.

[Consult the corresponding ReadMe.txt]


#>

param([string]$source = "C:", [string]$target = "C:")

#This may or may not be needed, but was used to indicate the source drive for the attachments
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptDriveRoot = $scriptPath.Substring(0, 2)

#Source Path...
$pathToApplicationImages = "$source\ApplicationImages_Prod"

$startTime = Get-Date
$timeDateStamp = $(get-date -f yyyy-MM-dd)

$attachmentsRootDir = "$target\Escrow\Attachments"
$attachmentsDir = "$attachmentsRootDir\$timeDateStamp\Attachments"
$reportDir = "\rpt"

<#
Thank you to Mike Reily for providing very clean SQL query to get the proper attachment file list!
#>
$connectionString = "data source=SQLM01Dev,1705;initial catalog=XcelWeb_Prod;user=xceligentuser;password=xceligentuser"
$query = @" 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- Suite attachments
SELECT  a.Attachmentid ,
        a.Path ,
        a.OptPath ,
        a.RptPath
FROM    Attachment a
        INNER JOIN SuiteAttachment sa ON sa.AttachmentId = a.AttachmentId
        INNER  JOIN suite s ON s.SuiteId = sa.SuiteId
        INNER JOIN listing l ON l.listingid = s.listingid
        INNER JOIN property p ON p.propertyid = l.propertyid
WHERE   ( l.OwnerMetroCode = 340
          OR p.AddressMetroCode = 340
          OR a.OwnerMetroCode = 340
        )
            
-- Listing attachments
UNION ALL
SELECT  a.Attachmentid ,
        a.Path ,
        a.OptPath ,
        a.RptPath
FROM    Attachment a
        INNER JOIN listing_attachment la ON la.AttachmentId = a.AttachmentId
        INNER JOIN Listing l ON l.listingid = la.listingid
        INNER JOIN property p ON p.propertyid = l.propertyid
WHERE   ( l.OwnerMetroCode = 340
          OR p.AddressMetroCode = 340
          OR p.OwnerMetroCode = 340
          OR a.OwnerMetroCode = 340
        )
        
-- Property attachments                                 
UNION ALL
SELECT  a.Attachmentid ,
        a.Path ,
        a.OptPath ,
        a.RptPath
FROM    Attachment a
        INNER JOIN PropertyAttachment pa ON pa.AttachmentId = a.AttachmentId
        INNER JOIN property p ON p.PropertyId = pa.PropertyId
WHERE   ( p.AddressMetroCode = 340
          OR p.OwnerMetroCode = 340
          OR a.ownermetrocode = 340
        )            
            
-- Sale Comp attachments
UNION ALL
SELECT  a.Attachmentid ,
        a.Path ,
        a.OptPath ,
        a.RptPath
FROM    Attachment a
        INNER JOIN dbo.VerifiedSaleAttachment vsa ON vsa.AttachmentId = a.AttachmentId
        INNER JOIN sale s ON s.VerifiedSaleID = vsa.VerifiedSaleId
        INNER JOIN verifiedsale vs ON vs.VerifiedSaleId = s.VerifiedSaleID
        INNER JOIN property p ON s.PropertyId = p.PropertyId
WHERE   ( p.AddressMetroCode = 340
          OR p.OwnerMetroCode = 340
          OR s.OwnerMetroCode = 340
          OR a.OwnerMetroCode = 340
        )
"@
$attachmentsCount = 0
$attachmentsThumbsCount = 0
$attachmentsReportsCount = 0

<#
BEGIN Script Execution
#>

"
Script Start-Time: $startTime
"
Write-Host "Example Source/Destination directories: 

From: $pathToApplicationImages\Attachments\[###]\[AttachmentId].jpg
To: $attachmentsDir\Attachments\[###]\[AttachmentId].jpg

If any of this looks incorrect, please press Ctrl-C now...

" -ForegroundColor Red 


<#
Functions
#>

function ShowFileCount($DataTable)
{
	$rowIndex = 0
	$rowCount = $DataTable.Rows.Count
	$lastPercent
	foreach($row in $DataTable.Rows)
	{
		$rowIndex++
		$percent =  [math]::round(($rowIndex / $rowCount)*100, 1)
		if($lastPercent -ne $percent)
		{
			$lastPercent = $percent
			write-progress -activity "Collecting File Counts" -status "$percent% Complete:" -percentcomplete $percent
		}
		
		$attachment = $($Row["Path"]).Replace("/", "\")
		$attachmentThumb = $($Row["OptPath"]).Replace("/", "\")
		$attachmentReport = $($Row["RptPath"]).Replace("/", "\")
		
		<# Check & Copy for Attachment #>
		if($attachment){ 
			$attachmentsCount++
		}

		<# Check & Copy for Attachment Thumbnail #>
		if($attachmentThumb){ 
			$attachmentsThumbsCount++
		}

		<# Check & Copy for Attachment Report #>
		if($attachmentReport){ 
			$attachmentsReportsCount++
		}
	}
	$endTime = Get-Date
	$elapsedTime = $endTime - $startTime

	"
	Attachment Files: $attachmentsCount
	Thumbnail Files: $attachmentsThumbsCount
	Report Files: $attachmentsReportsCount
	---
	Total: $($attachmentsCount + $attachmentsThumbsCount + $attachmentsReportsCount) files
	"
}


<#Prep the directory structures... #>
if(Test-Path $attachmentsRootDir){
	"
	
	Removing files from $attachmentsRootDir
	...this might take quite a while, considering there are potentially 1.5 million files.
	
	"
	Remove-Item -Recurse -Force $attachmentsRootDir
}
New-Item -ItemType Directory -Force -Path $attachmentsDir | Out-Null


<# Setup the directory structure for the files to be copied to... Copy-Item -force doesn't quite work well here.#>
for($i=0;$i -le 999; $i++){
	$newDir = $i.ToString("000")
	New-Item -ItemType Directory -Force -Path $attachmentsDir\$newDir | Out-Null
	New-Item -ItemType Directory -Force -Path $attachmentsDir$reportDir\$newDir | Out-Null
}

<# Make the data connection and get the file list... #>

Write-Host "Executing SQL to get list of attachment files... "

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText = $query
$result = $command.ExecuteReader()
$table = new-object “System.Data.DataTable”
$table.Load($result)
Write-Host "SQL Execution complete.... "
$connection.Close()

<# Display to user the amount of files that are going to be copied... #>
ShowFileCount $table

Write-Host "Starting to copy files to temporary location ($attachmentsDir)"
$rowIndex = 0
$rowCount = $table.Rows.Count
$lastPercent = 0
		
foreach($row in $table.Rows)
{
	$rowIndex++
	$percent =  [math]::round(($rowIndex / $rowCount)*100, 1)
	if($lastPercent -ne $percent)
	{
		$lastPercent = $percent
		write-progress -activity "Copying Files" -status "$percent% Complete:" -percentcomplete $percent
	}
	<# Set the three vars we need for copying... #>
	$attachment = $($Row["Path"]).Replace("/", "\")
	$attachmentThumb = $($Row["OptPath"]).Replace("/", "\")
	$attachmentReport = $($Row["RptPath"]).Replace("/", "\")
	
	<# Check & Copy for Attachment #>
	$srcAttachmentPath = "$pathToApplicationImages$attachment"
	$destAttachmentPath = "$attachmentsDir$attachment"
	if(Test-Path $srcAttachmentPath){ 
		Copy-Item $srcAttachmentPath $destAttachmentPath -Force
		$attachmentsCount++
	}

	<# Check & Copy for Attachment Thumbnail #>
	$srcThumbAttachmentPath = "$pathToApplicationImages$attachmentThumb"
	$destThumbAttachmentPath = "$attachmentsDir$attachmentThumb"
	if(Test-Path $srcThumbAttachmentPath){ 
		Copy-Item $srcThumbAttachmentPath $destThumbAttachmentPath -Force
		$attachmentsThumbsCount++
	}

	<# Check & Copy for Attachment Report #>
	$srcReportAttachmentPath = "$pathToApplicationImages$attachmentReport"
	$destReportAttachmentPath = "$attachmentsDir$attachmentReport"
	if(Test-Path $srcReportAttachmentPath){ 
		Copy-Item $srcReportAttachmentPath $destReportAttachmentPath -Force
		$attachmentsReportsCount++
	}
}

$endTime = Get-Date
$elapsedTime = $endTime - $startTime

"
Complete.

Attachment Files: $attachmentsCount
Thumbnail Files: $attachmentsThumbsCount
Report Files: $attachmentsReportsCount
---
Total: $($attachmentsCount + $attachmentsThumbsCount + $attachmentsReportsCount) files

Duration:
{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours

"
Files were copied to:
$attachmentsDir

"
