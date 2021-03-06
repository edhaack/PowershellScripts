#New Virtual Directory Tests...

function CreateUNCVirtualDirectory(
    [string]$siteName = $(throw "Must provide a Site Name"),
    [string]$vDirName = $(throw "Must provide a Virtual Directory Name"),
    [string]$uncPath = $(throw "Must provide a UNC path"),
    [string]$uncUserName = $(throw "Must provide a UserName"),
    [string]$uncPassword = $(throw "Must provide a password")
    ) {

    $iisWebSite = Get-WmiObject -Namespace 'root\MicrosoftIISv2' -Class IISWebServerSetting -Filter "ServerComment = '$siteName'"

    $virtualDirSettings = [wmiclass] "root\MicrosoftIISv2:IIsWebVirtualDirSetting"
    $newVDir = $virtualDirSettings.CreateInstance()
    $newVDir.Name = ($iisWebSite.Name + '/ROOT/' + $vDirName)
    $newVDir.Path = $uncPath
    $newVDir.UNCUserName = $uncUserName
    $newVDir.UNCPassword = $uncPassword

    # Call GetType() first so that Put does not fail.
    # http://blogs.msdn.com/powershell/archive/2008/08/12/some-wmi-instances-can-have-their-first-method-call-fail-and-get-member-not-work-in-powershell-v1.aspx
    Write-Warning 'Ignore one error message:Exception calling "GetType" with "0" argument(s): "You cannot call a method on a null-valued expression."'
    $newPool.GetType()

    $newVDir.Put();
    if (!$?) { $newVDir.Put() }
}

$defaultSiteName = "Default Web Site"
$user = "xceligent\cdxuser"
$pass = "no#Nsense*"

CreateUNCVirtualDirectory $defaultSiteName "CDXDirectLogs" "\\StateM01Dev\PrivateBranding_Prod\CDXDirectLogs" $user $pass
