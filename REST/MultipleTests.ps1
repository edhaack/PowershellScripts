#requires -version 2
<#
.SYNOPSIS
  MultipleTests.ps1

.DESCRIPTION
  Execute all Robot Framework Tests within the given directory.

  (Note: Prior to running this, read docs here: https://github.com/robotframework/RIDE/wiki/Installation-Instructions )

1. Get directory with Robot Tests... (as TeamCity Parameter)
2. loop through each file with extension .robot - In numeric order (such as the SQL execution script)
3. Split filename into TestRail CaseID & description
4. Determine Result file from description part
5. Run Robot Test
6. Read Results to get variables for TestRail API Calls.
7. Create TestRail Run
8. Create TestRail Results for Case (Case ID Provided)

TestRail URL: https://xceligentqa.testrail.net/index.php?/cases/view/7&group_by=cases:section_id&group_order=asc&group_id=1

API Example: curl -k -H "Content-Type: application/json" -u "ehaack@xceligent.com:PzMS8fbbnpieF2LWl4uY-qRzohuMpCMNMC32WXRBs" "https://xceligentqa.testrail.net/index.php?/api/v2/get_result_fields"


.PARAMETER $projectId
.PARAMETER $robotVariables
.PARAMETER $robotAdditionalParams
.PARAMETER $sourceDirectory

.NOTES
  Version:        1.0
  Author:         E.S.H.
  Creation Date:  7/11/2016
  Purpose/Change: Initial script development
  
.EXAMPLE
  MultipleTests.ps1 ".\Tests\XRC" "PROJECT_ENV:http://xrc-dev.xceligent.org" "-v PROJECT:xrc -v BROWSER:phantomjs -v LOGIN_URL:/Account/Login" "P1"
  
  TEAMCITY: 
  MultipleTests.ps1 %Robot.Test.Directory.Path% %Robot.Variables% %Robot.Extra.Parameters% %TestRail.Project.Id%
#>

Param (
	[string] $sourceDirectory = ".\Tests\XRC"
	,[string] $robotVariables = "PROJECT_ENV:http://xrc-dev.xceligent.org"
	,[string] $robotAdditionalParams = "-v PROJECT:xrc -v BROWSER:phantomjs -v LOGIN_URL:/Account/Login"
	,[string] $projectId = "3"
	,[string] $buildId = "35983"
	,[string] $buildTypeId = "AutomatedTests_Xrc_DevExecuteAllRobotTestCases"
	,[string] $buildTab = "report_project43_Test_Results"
	,[string] $buildNumber = "123"
	,[string] $testRailRunTitle = "DEV - SMOKE"
	,[Parameter(Mandatory=$True)]
	[ValidateNotNull()]
	[string] $testRailUserName
	,[Parameter(Mandatory=$True)]
	[ValidateNotNull()]
	[string] $testRailApiKey

)

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name
$startTime = Get-Date
$timeDateStamp = $(Get-Date -f yyyy-MM-dd.HH.mm)
$logFile = "$scriptName-$timeDateStamp.log"
$doOutputFile = $false
#For Exceptions
$shouldSendEmailOnException = $false
$smtpServer = "smtp.xceligent.org"
$emailFrom = "teamcity@xceligent.com"
$emailTo = "ehaack@xceligent.com"

#for local testing
#$sourceDirectory = "{0}\tests\RobotTests\Tests\XRC" -f $scriptPath
#$sourceDirectory
#$robotVariables = "PROJECT_ENV:http://xrc-dev.xceligent.org"
#$robotAdditionalParams = "-v PROJECT:xrc -v BROWSER:phantomjs -v LOGIN_URL:/Account/Login"
#$projectId = "P1"

#Local Variables
$testRailApiUrl = "https://xceligent.testrail.net/index.php?/api/v2/"

#Parameter cleanup
if($sourceDirectory.StartsWith(".\")) {
	$sourceDirectory = $sourceDirectory.Replace(".\", "{0}\" -f $scriptPath);
}
$robotFileSplitChar = "-"
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#-----------------------------------------------------------[Functions - Script Specific]------------------------------------------
$testRailApiUrl = "https://xceligent.testrail.net/index.php?/api/v2/"
$testRailUserName = "xceligentapplications@gmail.com"
$testRailApiKey = "7VRb1lZoY8mO9NB40mN/-GF0wEzE3/Af08cWribbd"
$testRailSuccessId = "1"
$testRailFailId = "5"

function SslCertificateCheckDisable() {
	add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
	[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

function GetRestHeaders($userName, $userPassword) {
	$pair = "{0}:{1}" -f $userName, $userPassword
	$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
	$base64 = [System.Convert]::ToBase64String($bytes)
	$basicAuthValue = "Basic $base64"

	$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
	$headers.Add("Authorization", $basicAuthValue)
	$headers.Add("Accept", "application/json")
	return $headers
}

function ExecuteGetRequest($method) {
	SslCertificateCheckDisable
	$headers = GetRestHeaders $testRailUserName $testRailApiKey
	$apiUri = "{0}{1}" -f $testRailApiUrl, $method
	$response = Invoke-RestMethod -Headers $headers -ContentType "application/json" -Uri $apiUri -Method Get
	return $response
}

function ExecutePostRequest($method, $body) {
	SslCertificateCheckDisable
	$headers = GetRestHeaders $testRailUserName $testRailApiKey
	$apiUri = "{0}{1}" -f $testRailApiUrl, $method
	write-host $apiUri
	if($body) {
		$response = Invoke-RestMethod -Headers $headers -ContentType "application/json" -Uri $apiUri -Method Post -Body $body
	} else {
		$response = Invoke-RestMethod -Headers $headers -ContentType "application/json" -Uri $apiUri -Method Post
	}
	return $response
}

function GetTestRailCaseInfo($caseId) {
	$method = "get_case/{0}" -f $caseId
	$response = ExecuteGetRequest $method
	return $response
}

function GetTeamCityLink() {
	#$buildId = "35983" #TODO Get these values from TeamCity
	#$buildTypeId = "AutomatedTests_Xrc_DevExecuteAllRobotTestCases"
	#$buildTab = "report_project43_Test_Results"
	#$buildNumber = "123"
	$tcReportLink = "http://teamcity01.xceligent.org:8181/viewLog.html?buildId={0}&buildTypeId={1}&tab={2}" -f $buildId, $buildTypeId, $buildTab
	return $tcReportLink
}

function CreateTestRailRun($projectId, $caseIds) {
	$teamCityUserId = 10
	$tcReportLink = GetTeamCityLink
	$finalCaseIds = $caseIds | ConvertToArray

	#Create the Run @ TestRail
	$testRailRunTitle = $testRailRunTitle.Replace("'", "")
	$runName = "{0} ({1})" -f $testRailRunTitle, $timeDateStamp
	$body = @{name=$runName;description="TeamCity: $tcReportLink";assignedto_id=$teamCityUserId;include_all=$false;case_ids=$caseIds} | ConvertTo-Json
	$method = "add_run/{0}" -f $projectId
	$response = ExecutePostRequest $method $body
	return $response.id
}

function GetBuildVersion() {
	return "1.0 Build {0}" -f $buildNumber
}

function CreateTestRailResult($runId, $caseId, $testIsPass, $testElapsed, $robotTestContents){
	#Create the Result entry for the Run
	"Creating result for case"
	$response = GetTestRailCaseInfo $caseId
	$caseTitle = $response.title
	$tcReportLink = GetTeamCityLink
	$version = GetBuildVersion

	if($testIsPass) { $statusId = $testRailSuccessId; } else { $statusId = $testRailFailId; }
	$comment = "C{0} - {1} ({2}) | Robot Test File Contents: {3}" -f $caseId, $caseTitle, $timeDateStamp, $robotTestContents
	$body = @{status_id=$statusId;comment=$comment;elapsed=$testElapsed;version=$version} | ConvertTo-Json
	$method = "add_result_for_case/{0}/{1}" -f $runId, $caseId
	$body
	$response = ExecutePostRequest $method $body
	$response
}

function IsValidRobotFile($file) {
	$file = $file.toLower()
	if($file.StartsWith("x-")) { return $false; }
	if($file.indexOf($robotFileSplitChar) -lt 0) { return $false; }
	return $true
}

function GetValidRobotFiles($files) {
	$validFiles = New-Object System.Collections.ArrayList
	foreach ($file in $files)
	{
		$robotFilename = $file.name
		$robotFullPath = $file.fullname
		#Rules Check...
		if(!(IsValidRobotFile $robotFilename)) {
			continue; 
		}
		#Get CaseID & Description...
		$testrailCaseId,$testrailFullDescription = $robotFilename.split($robotFileSplitChar,2);
		#$testrailDescription,$robotFileExt = $testrailFullDescription.split(".",2);
		#$resultsDirectory = "{0}\{1}" -f $resultsBaseDirectory, $testrailCaseId
		$testrailCaseId = $testrailCaseId.Replace("C", "")

		#Test the CaseID for valid id...
		try {
			$result = GetTestRailCaseInfo $testrailCaseId
		}
		catch {
			continue;
		}
		$validFiles.Add($robotFilename);
	}
	return $validFiles
}

function ConvertToArray{END{ return ,@($input) }}

function MultipleTests() {
	#Create Results Directory
	$resultsBaseDirectory = "{0}\Results" -f $scriptPath
	if(Test-Path $resultsBaseDirectory) { Remove-Item $resultsBaseDirectory -Recurse -Force }

	#Loop thru all .robot files in the dir...
	$robotFiles = Get-ChildItem -path "$sourceDirectory\" -Filter *.robot | sort-object
	if($robotFiles.count -lt 1) { 
		"No valid robot files to run. Cancelling."
		return;
	}

	$robotFileList = New-Object System.Collections.ArrayList
	$caseIds = New-Object System.Collections.ArrayList

	#Get valid robot files + caseIds
	foreach ($file in $robotFiles)
	{
		$robotFilename = $file.name
		#Rules Check...
		if(!(IsValidRobotFile $robotFilename)) {
			continue; 
		}
		#Get CaseID & Description...
		$testrailCaseId,$testrailFullDescription = $robotFilename.split($robotFileSplitChar,2);
		$testrailCaseId = $testrailCaseId.Replace("C", "")

		#Test the CaseID for valid id...
		try {
			$result = GetTestRailCaseInfo $testrailCaseId
		}
		catch {
			continue;
		}

		$caseIds.Add($testrailCaseId);
		$robotFileList.Add($robotFilename);
	}

	if($robotFileList.count -lt 1) { 
		"No valid robot files to run. Cancelling."
		return;
	}

	$runId = CreateTestRailRun $projectId $caseIds
	"TestRail - Run created! "

	foreach ($file in $robotFileList)
	{
		$robotFilename = $file

		#Get CaseID & Description...
		$testrailCaseId,$testrailFullDescription = $robotFilename.split($robotFileSplitChar,2);
		$testrailDescription,$robotFileExt = $testrailFullDescription.split(".",2);
		$resultsDirectory = "{0}\{1}" -f $resultsBaseDirectory, $testrailCaseId
		$testrailCaseId = $testrailCaseId.Replace("C", "")

		#execute Robot test...
		$robotFullPath = "{0}\{1}" -f $sourceDirectory, $file
		$robotVariables = $robotVariables.Replace("'", "")
		$robotAdditionalParams = $robotAdditionalParams.Replace("'", "")
		$robotVariables
		$robotAdditionalParams
		$robotExe = "robot -d {0} -v {1} {2} `"{3}`"" -f $resultsDirectory, $robotVariables, $robotAdditionalParams, $robotFullPath
		$robotExe
		Invoke-Expression $robotExe

		#Read values from each output.xml (from robot results) and determine PASS or FAIL
		$outputFilename = "{0}\output.xml" -f $resultsDirectory
		$isFailTest = Select-String $outputFilename -pattern "status=`"FAIL`""
		$isPass = $true
		if($isFailTest) {
			$isPass = $false
		}
		"Test Pass?: {0}" -f $isPass

		$robotTestContents = Get-Content $robotFullPath -Raw

		#TODO Get Elapsed...
		$elapsed = "30s"
		CreateTestRailResult $runId $testrailCaseId $isPass $elapsed $robotTestContents
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
	$rebotExe = "rebot --name `"All Tests`" --outputdir {0}\Results {0}\Results\*\*.xml" -f $scriptPath
	$rebotExe
	Invoke-Expression $rebotExe


}

#-----------------------------------------------------------[Functions - Core]-----------------------------------------------------

function Main {
	#Begin primary code.
	$errorCode = 0
	try {
		MultipleTests
	}
	catch {
		HandleException $_ 
		$errorCode = 1
	}
	finally {
	
	}
	if(!($errorCode -eq 0)) {
		Write-Host "Exiting with error $errorCode"
		exit $errorCode 
	}
}

function HandleException($exceptionObject) {
	$errorMessageBuilder = New-Object System.Text.StringBuilder
	$errorMessageBuilder.Append("$scriptName : An error occurred`r`n`r`n")
	$errorMessageBuilder.Append("Exception Type: $($exceptionObject.Exception.GetType().FullName)`r`n")
	$errorMessageBuilder.Append("Exception Message: $($exceptionObject.Exception.Message)`r`n")
	$errorMessageBuilder.Append("`r`n")

	$errorMessage = $errorMessageBuilder.ToString()

    Write-Host "Caught an exception:" -ForegroundColor Red
	Write-Host $errorMessage -ForegroundColor Red
	
	if($shouldSendEmailOnException -eq $true){
		Write-Host "Sending email to: $emailTo"
		
		$emailMessage = New-Object System.Net.Mail.MailMessage( $emailFrom , $emailTo )
		$emailMessage.Subject = "{0}-{1} Failure" -f $scriptPath, $scriptName
		$emailMessage.IsBodyHtml = $false
		$emailMessage.Body = $errorMessage

		$SMTPClient = New-Object System.Net.Mail.SmtpClient( $smtpServer )
		$SMTPClient.Send( $emailMessage )
	}
}

function ShowScriptBegin() {
	cls
	if($doOutputFile){
		Start-Transcript -path $logFile -append
	}
	"
	Script Start-Time: $startTime
	"
}

function ShowScriptEnd() {
	$endTime = Get-Date
	$elapsedTime = $endTime - $startTime
	"
	Complete at: $endTime

	Duration:
	{2} hours, {0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Hours
	if($doOutputFile){
		Stop-Transcript
	}
	
#	Write-Host "Press any key to continue ..."
#	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

ShowScriptBegin
Main
ShowScriptEnd
