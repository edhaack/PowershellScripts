<#
XPRO: Robot Runner: Projects Object Data...
#>
$xproProject = @{};
$xproProject.Id = "CDX-10"; #Looks for this value in the selected path (when right-clicked)
$xproProject.Name = "XPro";
$xproProject.TestRailId = "1";
$xproProject.ResultsRootDirectory = "C:\Webistes\XPro" #Final format will be C:\Websites\XPro\[]

$xproDev = @{};
$xproDev.Name = "DEV";
$xproDev.RobotVariables = "PROJECT_ENV:http://xpro-dev.xceligent.org";
$xproDev.RobotAdditionalParameters = "-v PROJECT:xpro -v BROWSER:gc -v LOGIN_URL:/#/login -v username:mwillesensocal -v password:Disco123 -e Prod -e Fullscreen";

$xproQa = @{};
$xproQa.Name = "QA";
$xproQa.RobotVariables = "PROJECT_ENV:http://xpro-qa.xceligent.org";
$xproQa.RobotAdditionalParameters = "-v PROJECT:xpro -v BROWSER:gc -v LOGIN_URL:/#/login -v username:mwillesensocal -v password:Disco123 -e Prod -e Fullscreen";

$xproUat = @{};
$xproUat.Name = "UAT";
$xproUat.RobotVariables = "PROJECT_ENV:http://xpro-uat.xceligent.org";
$xproUat.RobotAdditionalParameters = "-v PROJECT:xpro -v BROWSER:gc -v LOGIN_URL:/#/login -v username:mwillesensocal -v password:Disco123 -e Prod -e Fullscreen";

$xproDq = @{};
$xproDq.Name = "PROD";
$xproDq.RobotVariables = "PROJECT_ENV:https://www.xceligentpro.com";
$xproDq.RobotAdditionalParameters = "-v PROJECT:xpro -v BROWSER:gc -v LOGIN_URL:/#/login -v username:mwillesensocal -v password:Disco123 -e Prod -e Fullscreen";

$xproEnvironments = @();
$xproEnvironments += $xproDev;
$xproEnvironments += $xproDq;
$xproEnvironments += $xproQa;
$xproEnvironments += $xproUat;

$xproProject.Environments = $xproEnvironments;

#END OF LINE