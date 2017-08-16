<#
Robot Runner: Robot Framework Test Runner (from Windows Context Menu)
2017.05.05 EHaack
Based on TeamCity Robot Runner
#>
# $environment = "DEV"
# $workingDirectory = "D:\GitHub\XRC\RobotTests\Tests\Smoke"

$environment = $args[0] 
$workingDirectory = $args[1]
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#exit immediately if empty...
if(!($environment)) { exit 1; }
if(!($workingDirectory)) { exit 1; }
if(!(Test-Path $workingDirectory)) { exit 1;}

. $scriptPath\ProjectData\ProjectManifest.ps1 #Project Data
. $scriptPath\HelperFunctions\VariableHelpers.ps1
. $scriptPath\HelperFunctions\RestHelpers.ps1
. $scriptPath\HelperFunctions\TestRailHelpers.ps1

#Variable Helper:
<# Sets the following variables...#>
$testRunVariables = SetCurrentTestRunVariables $environment $workingDirectory $projects
if(!($testRunVariables)) {
	Write-Host "Exiting. Unable to run based on the current selection." -ForegroundColor Red
	exit 1;
}
$robotVariables = $testRunVariables.robotVariables;
$robotAdditionalParams = $testRunVariables.robotAdditionalParams;
$useTestRail = $testRunVariables.useTestRail;
$projectId = $testRunVariables.projectId;
$testRailRunTitle = $testRunVariables.testRailRunTitle;
$resultsBaseDirectory = $testRunVariables.resultsBaseDirectory;

#BEGIN PRIMARY SCRIPT
$timeStamp = $(Get-Date -f HH:mm)
$testRailEnabled = if ($useTestRail -eq "true") { $true } else { $false }
$buildNumber = $(Get-Date -f yyyy.MM.dd) #Date is the build number...
[string] $robotFileSplitChar = "-"

function IsValidRobotFile($file) {
	$file = $file.toLower()
	if($file.StartsWith("x-")) { return $false; }
	if($file.indexOf($robotFileSplitChar) -lt 0) { return $false; }
	return $true
}

function Main() {
    #Write out some initial values to user...
    Write-Host "Running Tests in: $workingDirectory"
    Write-Host "Results will go to: $resultsBaseDirectory"
    "Debug: TestRailEnabled: {0}" -f $testRailEnabled

    try {
        #copy chromedriver to current directory...
        if(!(Test-Path $workingDirectory\chromedriver.exe)) {
            Copy-Item $workingDirectory\..\..\chromedriver.exe $workingDirectory -Force
        }
    }
    catch {
        "couldn't copy chromedriver... :( Hopefully it's in the path!"
    }

	# Change to working directory - 2017.02.22 - See notes.
	cd -path $workingDirectory

	# Remove Results Directory, if exists...
	if(Test-Path $resultsBaseDirectory) { Remove-Item $resultsBaseDirectory -Recurse -Force }

	#Loop thru all .robot files in the dir...
	$robotFiles = Get-ChildItem -path "$workingDirectory\" -Filter *.robot | sort-object
	if($robotFiles.count -lt 1) {
		"No valid robot files in the directory to run."
		return;
	}

	# We have .robot files...
	$robotFileList = New-Object System.Collections.ArrayList
	$caseIds = New-Object System.Collections.ArrayList

	# Get valid .robot files + caseIds (check if Test Cases are in TestRail)
	foreach ($file in $robotFiles)
	{
		$robotFilename = $file.name
		#Rules Check...
        $isValid = IsValidRobotFile $robotFilename
        if(!($isValid)) { continue; }
		#Get CaseID & Description...
		$testrailCaseId,$testrailFullDescription = $robotFilename.split($robotFileSplitChar,2);
		$testrailCaseId = $testrailCaseId.Replace("C", "")
		#Test the CaseID for valid id... (first TestRail API Call!)
		try { $result = GetTestRailCaseInfo $testrailCaseId }
		catch {	continue; }
        [void] $caseIds.Add($testrailCaseId);
        [void] $robotFileList.Add($robotFilename);
	}

	#Check filtered robot file rules array...
	if($robotFileList.count -lt 1) { 
		"There are .robot files, but Cases not found in TestRail."
		return;
	}

	# We have valid .robot files, begin the Test Run...
	$runId = CreateTestRailRun $projectId $caseIds

	foreach ($file in $robotFileList)
	{
		$robotFilename = $file

		#Get CaseID & Description...
		$testrailCaseId,$testrailFullDescription = $robotFilename.split($robotFileSplitChar,2);
		$testrailDescription,$robotFileExt = $testrailFullDescription.split(".",2);
		$resultsSubDirectory = $testrailCaseId
		$resultsDirectory = "{0}\{1}" -f $resultsBaseDirectory, $resultsSubDirectory
		$testrailCaseId = $testrailCaseId.Replace("C", "")

		$tcTestName = $testrailDescription
        "Robot File: $robotFilename"

		#execute Robot test...
		$robotFullPath = "{0}\{1}" -f $workingDirectory, $file
		$robotVariables = $robotVariables.Replace("'", "")
		$robotAdditionalParams = $robotAdditionalParams.Replace("'", "")
		$robotExe = "robot -d {0} -v {1} {2} `"{3}`"" -f $resultsDirectory, $robotVariables, $robotAdditionalParams, $robotFullPath
		
		[System.Diagnostics.Stopwatch] $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
		Invoke-Expression $robotExe
        [void] $stopWatch.Stop()
		$timeSpan = $stopWatch.Elapsed
		if($timeSpan.Minutes -eq 0) {
			$elapsed = "{0:0}s" -f $timeSpan.Seconds
		} else {
			$elapsed = "{0:0}m {1:0}s" -f $timeSpan.Minutes, $timeSpan.Seconds
		}

        #Read values from each output.xml (from robot results) and determine PASS or FAIL
		$outputFilename = "{0}\output.xml" -f $resultsDirectory
		$isTestSuccess = Select-String $outputFilename -pattern "fail=`"0`""
        #If the test failed, retry...
		if(!($isTestSuccess)) {
            #Rerun the tests... 2017.01.20
            Start-Sleep 5 #pause for 5 seconds before testing again...
            "Re-running Failed Tests..."

            $rerunOutputFilename = "{0}\rerun.xml" -f $resultsDirectory
            $robotExe = "robot --rerunfailed {0} --output {1} -d {2} -v {3} {4} `"{5}`"" -f $outputFilename, $rerunOutputFilename, $resultsDirectory, $robotVariables, $robotAdditionalParams, $robotFullPath
            Invoke-Expression $robotExe

            #Replace the latest re-run output log to the original output log for reporting...
            #Note: Merging w/ Rebot combines the failed run, with the re-run, which isn't desired.
            if(Test-Path $outputFilename) { Remove-Item $outputFilename -Force }
            if(Test-Path $rerunOutputFilename ) { Rename-Item $rerunOutputFilename $outputFilename -Force }

			$isTestSuccess = Select-String $outputFilename -pattern "fail=`"0`""
		}

		#Check for images and updates results files to reflect correct path.
		$resultsLogPath = "{0}\log.html" -f $resultsDirectory
		$resultsReportPath = "{0}\report.html" -f $resultsDirectory
		CheckOutputForImages $outputFilename $resultsLogPath $resultsReportPath $resultsSubDirectory 

		$robotTestContents = Get-Content $robotFullPath -Raw

		CreateTestRailResult $runId $testrailCaseId $isTestSuccess $elapsed $robotTestContents

		# TeamCity Test Results
		if($isTestSuccess) {
			"Success!"
		} else {
			#Get Error message from Test Output xml...
			$xmlOutput = [xml](Get-Content $outputFilename)
			$status = $xmlOutput.robot.suite.test.status.'#text'
			$shortMsg = $status
			$status
			"Expected Status: Success, Actual Status: Failure"
		}
	}

	#Results should be generated at this point
	$hasResults = @(gci $resultsBaseDirectory).Count -gt 0
	if(!($hasResults)) { 
		"Missing results... No Tests Run."
		return; 
	}

	#Run 'Rebot' to combine the output and generate a report for the TeamCity Report Tab(s)
	#Check for any Results
	"==========================================="
	"Running Rebot!"
	$rebotExe = "rebot --name `"All Tests`" --outputdir {0} {0}\*\*.xml" -f $resultsBaseDirectory
	Invoke-Expression $rebotExe

    #Delete the chromedriver we copied earlier... 
    if(Test-Path $workingDirectory\chromedriver.exe) {Remove-Item $workingDirectory\chromedriver.exe -Force}

    #Open the local report...
    $reportPath = "{0}\report.html" -f $resultsBaseDirectory
    if(Test-Path $reportPath) {
        $localReportUrl = "file:\\{0}" -f $reportPath
        Start-Process -FilePath $localReportUrl
    }

}

Main