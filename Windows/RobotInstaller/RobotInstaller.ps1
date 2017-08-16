<#
.Synopsis Using Chocolatey & PIP, prepare the current workstation for running Robot Framework tests.

.DESCRIPTION
1. Install Chocolatey
2. Attempt to directly install robotframework ... should install python if not already done.

.NOTES 
2017.08.16 - ESH - Created
 - Update to continue and by-pass installing python & pip if already installed. If they are, chocolately isn't needed.


#>

$pythonExePath = "C:\Python27\python.exe";
$pipExePath = "C:\Python27\Scripts\pip.exe";

function UpdateEnvironmentPath() {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
}

function InstallChocolatey() {
    Write-Output "Ensuring the Chocolatey package manager is installed..."
    
    $chocolateyBin = [Environment]::GetEnvironmentVariable("ChocolateyInstall", "Machine") + "\bin"
    $chocInstalled = Test-Path "$chocolateyBin\cinst.exe"
    
    if (-not $chocInstalled) {
        Write-Output "Chocolatey not found, installing..."
        
        $installPs1 = ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
        Invoke-Expression $installPs1
        
        Write-Output "Chocolatey installation complete."
    } else {
        Write-Output "Chocolatey was found at $chocolateyBin and won't be reinstalled."
    }
}

function InstallPython27() {
    #Check for python exists... if not, install...
    if(Test-Path $pythonExePath) {
        "{0} exists... continuing..." -f $pythonExePath;
    } else {
        InstallChocolatey;
        & choco install python2 -y;
        UpdateEnvironmentPath;
    }
    #Check if pip exists... if not, install...
    if(Test-Path $pipExePath) {
        "{0} exists... continuing..." -f $pipExePath;
    } else {
        InstallChocolatey;
        & choco install pip -y;
    }
}

function InstallRobotFramework() {
    "InstallRobotFramework"
    #Note: When using choco install robotframework -source python, it attempts to install python3... which is not good.
    & pip install robotframework;
    & pip install robotframework-selenium2library;
    & pip install robotframework-DatabaseLibrary;
    & pip install robotframework-extendedselenium2library;
    #UpdateEnvironmentPath;
    # Need to confirm this is necessary:
    #& pip install https://pypi.python.org/packages/b2/25/b60fd3fe28f7102b8880078ca3c5ce8faac82e2d402ed943048f80ef57ad/pymssql-2.1.3-cp35-cp35m-win_amd64.whl
}

InstallPython27;
InstallRobotFramework;

Write-Host "Robot installation is complete!" -ForegroundColor Green;
"
To test your installation, type: robot --help
"
