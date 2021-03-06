<#
Created: 2014.03.24 ESH
Updated: 

PURPOSE:
Gets all of the AIR Attachments and will zip up, w/ time-date stamp.

#>
$destinationDrive = "L:\Escrow"


set-alias sz "$scriptPath\7z.exe" 
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
Thank you to M. Reily for providing very clean SQL query to get the proper attachment file list!
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


<#
BEGIN Script Execution
#>

"
Script is starting: $startTime

Gathering files for copying...

Files will be copied to:
$tempDir


"

<#Prep the directory structures... #>
if(!(Test-Path $attachmentsRootDir)){
	New-Item -ItemType Directory -Force -Path $attachmentsRootDir
}
if(!(Test-Path $attachmentsDir)){
	New-Item -ItemType Directory -Force -Path $attachmentsDir
}
if(Test-Path $tempDir){
	Write-Host "Removing files from $tempDir"
	Remove-Item -Recurse -Force $tempDir
}
for($i=0;$i -le 999; $i++){
	$newDir = $i.ToString("000")
	New-Item -ItemType Directory -Force -Path $tempDir\Attachments\$newDir | Out-Null
	New-Item -ItemType Directory -Force -Path $tempDir\Attachments$reportDir\$newDir | Out-Null
}

<# Make the data connection and get the file lists... #>

Write-Host "Executing SQL to get list of attachment files... "

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText = $query
 
$result = $command.ExecuteReader()
Write-Host "SQL Execution complete.... "

$table = new-object “System.Data.DataTable”
$table.Load($result)
$connection.Close()

Write-Host "Starting to copy files to temporary location ($tempDir)"
foreach($row in $table.Rows)
{
	$attachment = $($Row["Path"]).Replace("/", "\")
	$attachmentThumb = $($Row["OptPath"]).Replace("/", "\")
	$attachmentReport = $($Row["RptPath"]).Replace("/", "\")
	
	Write-Host "Working on: $attachment"
	
	$sourceAttachmentPath = "$scriptDriveRoot$pathToApplicationImages$attachment"
	$destAttachmentPath = "$tempDir$attachment"
	if(Test-Path $sourceAttachmentPath){ 
		Copy-Item $sourceAttachmentPath $destAttachmentPath -Force
	}
	
	$srcThumbAttachmentPath = "$scriptDriveRoot$pathToApplicationImages$attachmentThumb"
	$destThumbAttachmentPath = "$tempDir$attachmentThumb"
	if(Test-Path $srcThumbAttachmentPath){ 
		Copy-Item $srcThumbAttachmentPath $destThumbAttachmentPath -Force
	}
	
	$srcReportAttachmentPath = "$scriptDriveRoot$pathToApplicationImages$attachmentReport"
	$destReportAttachmentPath = "$tempDir$attachmentReport"
	if(Test-Path $srcReportAttachmentPath){ 
		Copy-Item $srcReportAttachmentPath $destReportAttachmentPath -Force
	}
}


$endTime = Get-Date
$elapsedTime = $endTime - $startTime

"
Complete.

Duration:
{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours

"
Files will be copied to:
$tempDir


"


<# All attachment files copied to temp/working directory, ready for zip #>
#Write-Host "Creating Attachments Zip File..."
#sz a $zipFilePath $tempDir -tzip

#Write-Host "Removing temporary files..."
#Remove-Item -Recurse -Force $tempDir
