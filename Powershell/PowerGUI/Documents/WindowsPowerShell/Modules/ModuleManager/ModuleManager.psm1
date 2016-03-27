if ($PGVersionTable.PGVersion.ToString() -ge '3.6.0.33' -and $PSVersionTable.CLRVersion.Major -ge 4)
{
	Import-Module $psScriptRoot\ModuleManager.last.psm1 -ArgumentList $PSScriptRoot -Force
}
else
{
	Import-Module $psScriptRoot\ModuleManager.old.psm1 -ArgumentList $PSScriptRoot -Force
}