<#===========================================================================
PURPOSE:

OVERVIEW:
1)
2)
3)

CREATED:
1.0 7/21/2015 - ESH - Initial release

UPDATED:
===========================================================================
#>
#$serverName = "WebM01Dev.xceligent.org"
$serverName = "teamcity01.xceligent.org"

(Get-WmiObject Win32_Service -ComputerName $serverName -Filter "Name='w3svc'").InvokeMethod("StopService", $null)
(Get-WmiObject Win32_Service -ComputerName $serverName -Filter "Name='w3svc'").InvokeMethod("StartService", $null)
