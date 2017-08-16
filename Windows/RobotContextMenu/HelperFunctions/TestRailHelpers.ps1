# TestRail Methods
#TESTRAIL CONSTANTS
[string] $testRailApiUrl = "https://xceligent.testrail.net/index.php?/api/v2/"
[string] $testRailSuccessId = "1"
[string] $testRailFailId = "5"
[string] $testRailUserName = "xceligentapplications@gmail.com" #TODO encrypt this value
[string] $testRailApiKey = "eQkkq3jvZfIIdkMTE7ma-oTX9AbgeHgdF9ZROmnWr"  #TODO encrypt this value

function GetTestRailCaseInfo($caseId) {
    if(!($testRailEnabled)) { return 0 }
	$method = "get_case/{0}" -f $caseId
	$response = ExecuteGetRequest $method
	return $response
}
function CreateTestRailRun($projectId, $caseIds) {
    if(!($testRailEnabled)) { return 0 }
	$teamCityUserId = 10
	$tcReportLink = $tcReportLink
	$finalCaseIds = $caseIds | ConvertToArray
	#Create the Run @ TestRail
	$testRailRunTitle = $testRailRunTitle.Replace("'", "")
	$runName = "{0}: Build#:{1} ({2})" -f $testRailRunTitle, $buildNumber, $timeStamp
	$body = @{name=$runName;description="TeamCity: $tcReportLink";assignedto_id=$teamCityUserId;include_all=$false;case_ids=$caseIds} | ConvertTo-Json
	$method = "add_run/{0}" -f $projectId
	$response = ExecutePostRequest $method $body
	return $response.id
}
function CreateTestRailResult($runId, $caseId, $testIsPass, $testElapsed, $robotTestContents){
    if(!($testRailEnabled)) { return 0 }
	#Create the Result entry for the Run
	"Creating result for case"
	$response = GetTestRailCaseInfo $caseId
	$caseTitle = $response.title
	$tcReportLink = $tcReportLink
	$version = $buildVersion

	if($testIsPass) { $statusId = $testRailSuccessId; } else { $statusId = $testRailFailId; }
	$comment = "C{0} - {1} ({2}) | Robot Test File Contents: {3}" -f $caseId, $caseTitle, $timeDateStamp, $robotTestContents
	$body = @{status_id=$statusId;comment=$comment;elapsed=$testElapsed;version=$version} | ConvertTo-Json
	$method = "add_result_for_case/{0}/{1}" -f $runId, $caseId
	$response = ExecutePostRequest $method $body
	return $response
}
function GetValidRobotFiles($files) {
	$validFiles = New-Object System.Collections.ArrayList
	foreach ($file in $files)
	{
		$robotFilename = $file.name
		$robotFullPath = $file.fullname
		#Rules Check...
		if(!(IsValidRobotFile $robotFilename)) { continue; }
		#Get CaseID & Description...
		$testrailCaseId,$testrailFullDescription = $robotFilename.split($robotFileSplitChar,2);
		$testrailCaseId = $testrailCaseId.Replace("C", "")
		#Test the CaseID for valid id...
		try {
			$result = GetTestRailCaseInfo $testrailCaseId
		}
		catch { continue; }
        [void] $validFiles.Add($robotFilename);
	}
	return $validFiles
}

function ConvertToArray{END{ return ,@($input) }}

function ReplaceValueInFile($fileToEdit, $lookFor, $replaceWith) {
	(Get-Content $fileToEdit).replace($lookFor, $replaceWith) | Set-Content $fileToEdit
}
function CheckOutputForImages($resultsOutputPath, $resultsLogPath, $resultsReportPath, $resultsSubDirectory) {
	$lookFor = "selenium-screenshot"
	$replaceWith = "{0}\{1}" -f $resultsSubDirectory, $lookFor
	ReplaceValueInFile $resultsOutputPath $lookFor $replaceWith
	ReplaceValueInFile $resultsLogPath $lookFor $replaceWith
	ReplaceValueInFile $resultsReportPath $lookFor $replaceWith
}
# TestRail Methods