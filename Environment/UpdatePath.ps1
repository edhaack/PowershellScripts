<#
When an update is made to the system/env path, run this to update the current running script:
#>

function UpdateEnvironmentPath() {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
}