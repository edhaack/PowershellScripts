<#
Code to maintain projects...
TODO: ELIMINATE THE NEED FOR THIS!
#>
. $scriptPath\ProjectData\XRC.ps1
. $scriptPath\ProjectData\XPro.ps1

$projects = @();
$projects += $xrcProject;
$projects += $xproProject;
