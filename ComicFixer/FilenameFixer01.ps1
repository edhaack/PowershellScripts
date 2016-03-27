Param($filePath='C:\comics')

Function RenameFiles($FilesToRename,$OldName,$NewName){

$FileListArray = @()
Foreach($file in Get-ChildItem $FilesToRename -Force -Recurse  | Where-Object {$_.attributes -notlike "Directory"})
{
    $FileListArray += ,@($file.name,$file.fullname)
}

Foreach($File in $FileListArray)
{
    IF ($File -match $OldName )
    {
        $FileName = $File[0]
        $FilePath = $File[1]

        $SName = $File[0]  -replace "[^\w\.@-]", " "

        $SName = $SName -creplace '(?m)(?:[ \t]*(\.)|^[ \t]+)[ \t]*', '$1'

        $NewDestination = $FilePath.Substring(0,$FilePath.Length -$FileName.Length)
        $NewNameDestination = "$NewDestination$SName"
        $NewNameDestination | Write-Host

        Move-Item -LiteralPath $file[1] -Destination $NewNameDestination
        $NewNameDestination | rename-item -newName {$_ -replace "$OldName", "$NewName" }

        }
    }
}


renamefiles  -FilesToRename $filePath -OldName "" -NewName ""