<#
FreeFileSync 
#>
$sourceDir = $args[0]
$targetDir = $args[1]
$ffsBatch = $args[2]

set-alias ffs "C:\Program Files\FreeFileSync\FreeFileSync.exe" 

ffs -leftdir $sourceDir -rightdir $targetDir $ffsBatch

#ffs -leftdir $sourceDir -rightdir $targetDir "C:\TFS\Common\Utility\Promotion Scripts\RolloutToTest\XceligentAppDiff.ffs_batch"

