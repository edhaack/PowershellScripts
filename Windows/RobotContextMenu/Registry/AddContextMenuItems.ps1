<#
PowerShell Version of the .reg file...
#>
$robotRunnerScriptPath = $args[0];

# $robotRunnerScriptPath = "D:\GitHub\DevOps\Powershell\VSProject\Library\Library\Windows\RobotContextMenu\RobotRunner.ps1"
if(!($robotRunnerScriptPath)) { "Missing path to RobotRunner.ps1"; exit 1;}

#Running simple script, passing current context...
$shellKeyName = "RobotRunner"
$scriptPath = $robotRunnerScriptPath.Replace("\", "\\")

#Start the magick...
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
$registryPathBase = "HKCR:\Directory\shell"

function CreateRegistryKey($basePath, $name, $value) {
    if(Test-Path $basePath) {
        New-Item -Path $basePath -Name $name -Value $value -Force
        Write-Host "Added: $basePath\$name : $value"
    }
}

function CreateRegistryItem($basePath, $name, $value) {
    if(Test-Path $basePath) {
        New-ItemProperty -Path $basePath -Name $name -Value $value -Force
        Write-Host "Added: $basePath\$name : $value"
    }
}

#Add the new key...
$keyName = "RobotRunner"
$value = ""
CreateRegistryKey $registryPathBase $keyName $value 
#Add property items & values
$registryPath = "{0}\{1}" -f $registryPathBase, $keyName
CreateRegistryItem $registryPath "MUIVerb" "Run Robot run!"
CreateRegistryItem $registryPath "subcommands" ""

CreateRegistryKey $registryPath "shell" ""
$registryPath = "{0}\shell" -f $registryPath
CreateRegistryKey $registryPath "env1" "Dev: TestRail Run"
CreateRegistryKey $registryPath "env2" "DQ: TestRail Run"
CreateRegistryKey $registryPath "env3" "QA: TestRail Run"
CreateRegistryKey $registryPath "env4" "UAT: TestRail Run"
CreateRegistryKey $registryPath "env5" "PROD: TestRail Run"

# @="powershell -noexit D:\\GitHub\\DevOps\\Powershell\\VSProject\\Library\\Library\\Windows\\RobotContextMenu\\RobotRunner.ps1 \"DQ\" \"%1\""

$shellCommandPrefix = "powershell -noexit -noprofile {0}" -f $scriptPath
$shellPath = $registryPath

$registryPath = "{0}\env1" -f $shellPath
$command = "{0} 'DEV' '%1'" -f $shellCommandPrefix
CreateRegistryKey $registryPath "command" $command

$registryPath = "{0}\env2" -f $shellPath
$command = "{0} 'DQ' '%1'" -f $shellCommandPrefix
CreateRegistryKey $registryPath "command" $command

$registryPath = "{0}\env3" -f $shellPath
$command = "{0} 'QA' '%1'" -f $shellCommandPrefix
CreateRegistryKey $registryPath "command" $command

$registryPath = "{0}\env4" -f $shellPath
$command = "{0} 'UAT' '%1'" -f $shellCommandPrefix
CreateRegistryKey $registryPath "command" $command

$registryPath = "{0}\env5" -f $shellPath
$command = "{0} 'PROD' '%1'" -f $shellCommandPrefix
CreateRegistryKey $registryPath "command" $command
