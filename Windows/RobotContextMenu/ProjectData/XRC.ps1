<#
XRC Robot Runner: Projects Object Data...
#>
$xrcProject = @{};
$xrcProject.Id = "XRC"; #Looks for this value in the selected path (when right-clicked)
$xrcProject.Name = "XRC";
$xrcProject.TestRailId = "2";
$xrcProject.ResultsRootDirectory = "C:\XRC\XRC\RobotTests\results" #Final format will be [rootDirectory]\[environment]\[testType], example: C:\XRC\XRC\RobotTests\results\DEV\SMOKE\

$xrcLocalHost = @{};
$xrcLocalHost.Name = "Localhost";
$xrcLocalHost.RobotVariables = "PROJECT_ENV:http://localhost{0}";
$xrcLocalHost.RobotAdditionalParameters = "-v PROJECT:xrc -v LOGIN_URL:/Account/Login";
$xrcLocalHost.useTestRail = $false;

$xrcDev = @{};
$xrcDev.Name = "DEV";
$xrcDev.RobotVariables = "PROJECT_ENV:http://xrc-dev.xceligent.org";
$xrcDev.RobotAdditionalParameters = "-v PROJECT:xrc -v LOGIN_URL:/Account/Login";

$xrcDq = @{};
$xrcDq.Name = "DQ";
$xrcDq.RobotVariables = "PROJECT_ENV:http://xrc-dq.xceligent.org";
$xrcDq.RobotAdditionalParameters = "-v PROJECT:xrc -v LOGIN_URL:/Account/Login";

$xrcQa = @{};
$xrcQa.Name = "QA";
$xrcQa.RobotVariables = "PROJECT_ENV:http://xrc-qa.xceligent.org";
$xrcQa.RobotAdditionalParameters = "-v PROJECT:xrc -v LOGIN_URL:/Account/Login";

$xrcUat = @{};
$xrcUat.Name = "UAT";
$xrcUat.RobotVariables = "PROJECT_ENV:http://xrc-uat.xceligent.org";
$xrcUat.RobotAdditionalParameters = "-v PROJECT:xrc -v LOGIN_URL:/Account/Login";

$xrcEnvironments = @();
$xrcEnvironments += $xrcLocalHost;
$xrcEnvironments += $xrcDev;
$xrcEnvironments += $xrcDq;
$xrcEnvironments += $xrcQa;
$xrcEnvironments += $xrcUat;

$xrcProject.Environments = $xrcEnvironments;

#END OF LINE