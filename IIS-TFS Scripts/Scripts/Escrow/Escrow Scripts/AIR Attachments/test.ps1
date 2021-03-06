<#
Created: 2014.03.24 ESH
Updated: 

PURPOSE:
Gets all of the AIR Attachments and will zip up, w/ time-date stamp.

[Consult the corresponding ReadMe.txt]
#>
$destinationDrive = "L:\Escrow"

$startTime = Get-Date
$timeDateStamp = $(get-date -f yyyy-MM-dd)

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptDriveRoot = $scriptPath.Substring(0, 2)
$tempDir = "$destinationDrive\Temp"

$attachmentsRootDir = "$destinationDrive\Attachments"
$attachmentsDir = "$attachmentsRootDir\$timeDateStamp"
$reportDir = "\rpt"

$zipFilePath = "$attachmentsDir\Attachments_$timeDateStamp.zip"

$pathToApplicationImages = "\ApplicationImages_Prod"

$connectionString = "data source=SQLM01Dev,1705;initial catalog=XcelWeb_Prod;user=xceligentuser;password=xceligentuser"

<#
Thank you to Mike Reily for providing very clean SQL query to get the proper attachment file list!
#>
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


<#
BEGIN Script Execution
#>

"
Script is starting: $startTime

Gathering files for copying...

Files will be copied to:
$tempDir


"


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

Write-Host "Starting to copy files to temporary location ($tempDir)"

ShowFileCount $table

Return

foreach($row in $table.Rows)
{
	<# Set the three vars we need for copying... #>
	
	
	$attachmentId = $($Row["Attachmentid"])
	$attachment = $($Row["Path"]).Replace("/", "\")
	$attachmentThumb = $($Row["OptPath"]).Replace("/", "\")
	$attachmentReport = $($Row["RptPath"]).Replace("/", "\")
	
	Write-Host "Working on: $attachmentId"
	
	<# Check & Copy for Attachment #>
	$srcAttachmentPath = "$scriptDriveRoot$pathToApplicationImages$attachment"
	$destAttachmentPath = "$tempDir$attachment"
	if(Test-Path $srcAttachmentPath){ 
		Copy-Item $srcAttachmentPath $destAttachmentPath -Force
		$attachmentsCount++
	}

	<# Check & Copy for Attachment Thumbnail #>
	$srcThumbAttachmentPath = "$scriptDriveRoot$pathToApplicationImages$attachmentThumb"
	$destThumbAttachmentPath = "$tempDir$attachmentThumb"
	if(Test-Path $srcThumbAttachmentPath){ 
		Copy-Item $srcThumbAttachmentPath $destThumbAttachmentPath -Force
		$attachmentsThumbsCount++
	}

	<# Check & Copy for Attachment Report #>
	$srcReportAttachmentPath = "$scriptDriveRoot$pathToApplicationImages$attachmentReport"
	$destReportAttachmentPath = "$tempDir$attachmentReport"
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
$tempDir


"


