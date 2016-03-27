Param($csvFile='sites.csv',$desktopDir='sites')
Write-Host "Loading... " $csvFile

$HostHeaderValue = "Host header value"
$WshShell = New-Object -comObject WScript.Shell
$Desktop = ("$Home\Desktop\{0}\" -f $desktopDir)
#test
$sites = import-csv $csvFile

#

foreach ($site in $sites) {
	if($site.State -eq "Stopped") { continue; }
	
	$description = $site.Description
	$url = $site.$($HostHeaderValue)
	$link = ("{0}{1}.url" -f $Desktop, $description)
	
	#Write link to be copied for WordPress Page
	write-host "<li>"
	write-host ("<a href='http://{0}' target='_blank'>{1}</a>" -f $url, $description )
	write-host "</li>"
	
	$Shortcut = $WshShell.CreateShortcut($link)
	$Shortcut.TargetPath = ("http://{0}" -f $url)
	$Shortcut.Save()
}  
