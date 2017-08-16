<#
VariableHelpers.ps1
Purpose: Set required variables based on Parameters and Data.

2017.05.08 . EHaack . Initial

Sets the following variables:
[string] $robotVariables
[string] $robotAdditionalParams
[string] $useTestRail = "true"
[string] $projectId
[string] $testRailRunTitle
[string] $resultsBaseDirectory

#>

function GetProjectFromDirectory ($projects, [string] $workingDirectory) {
    foreach($project in $projects){
        $currentId = $project.Id
        if($workingDirectory.IndexOf($currentId) -gt -1) {
            $projObject = New-Object -TypeName psobject -Property $project
            return $projObject
        }
    }
}

function GetEnvironment ($environments, $environmentName) {
    foreach($env in $environments){
        if($env.Name -eq $environmentName) {
            return $env
        }
    }
}

function SetCurrentTestRunVariables([string] $environment, [string] $workingDirectory, $projects) {
    #Get Project ID from workingDirectory
    $project = GetProjectFromDirectory $projects $workingDirectory
    if(!$project){ 
        Write-Host "Unable to find project by directory: $workingDirectory"
        return $null; 
    } #Opps... no data found!

    $env = GetEnvironment $project.Environments $environment
    if(!($env)) { 
        Write-Host "Environment not found: $environment"
        return $null
    }

    $projectType = Split-Path $workingDirectory -Leaf

    #Results Directory - example: C:\XRC\XRC\RobotTests\results\DEV\SMOKE
    $resultsBaseDirectory = "{0}\{1}\{2}" -f $project.ResultsRootDirectory, $env.Name, $projectType

    # "DEV - SMOKE (ComputerName)"
    $robotReportTitle = "{0} - {1} ({2})" -f $env.Name, $projectType, $env:computername

    $runVariables = @{};
    $runVariables.robotVariables = $env.RobotVariables
    $runVariables.robotAdditionalParams = $env.RobotAdditionalParameters
    $runVariables.useTestRail = if( $env.useTestRail -eq $false ) { "false" } else { "true"}
    $runVariables.projectId = $project.TestRailId
    $runVariables.testRailRunTitle = $robotReportTitle
    $runVariables.resultsBaseDirectory = $resultsBaseDirectory

    Write-Host "Primary variables for this run established."
    return $runVariables
}