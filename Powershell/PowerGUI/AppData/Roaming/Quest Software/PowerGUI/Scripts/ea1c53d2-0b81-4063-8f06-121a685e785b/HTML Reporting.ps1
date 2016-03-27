#region Define the Win32WindowClass

if (-not ('PowerShellTypeExtensions.Win32Window' -as [System.Type])) {
	$cSharpCode = @'
using System;

namespace PowerShellTypeExtensions {
	public class Win32Window : System.Windows.Forms.IWin32Window
	{
		public static Win32Window CurrentWindow {
			get {
				return new Win32Window(System.Diagnostics.Process.GetCurrentProcess().MainWindowHandle);
			}
		}
	
		public Win32Window(IntPtr handle) {
			_hwnd = handle;
		}

		public IntPtr Handle {
			get {
				return _hwnd;
			}
		}

		private IntPtr _hwnd;
	}
}
'@

	Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition $cSharpCode
}

#endregion
#region UI Functions

function global:Show-MessageBox {
	[CmdletBinding()]
	[OutputType([System.Windows.Forms.DialogResult])]
	param(
		[Parameter(Position=0,Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Text,

		[Parameter()]
		[ValidateNotNull()]
		[System.String]
		$Caption = '',

		[Parameter()]
		[ValidateNotNull()]
		[System.Windows.Forms.MessageBoxButtons]
		$Buttons = [System.Windows.Forms.MessageBoxButtons]::OK,

		[Parameter()]
		[ValidateNotNull()]
		[System.Windows.Forms.MessageBoxIcon]
		$Icon = [System.Windows.Forms.MessageBoxIcon]::None,

		[Parameter()]
		[ValidateNotNull()]
		[System.Windows.Forms.MessageBoxDefaultButton]
		$DefaultButton = [System.Windows.Forms.MessageBoxDefaultButton]::Button1,

		[Parameter()]
		[ValidateNotNull()]
		[System.Windows.Forms.MessageBoxOptions]
		$Options = 0
	)

	try {
		if ((Get-Process -Id $PID).ProcessName -match '^AdminConsole') {
			[System.Windows.Forms.MessageBox]::Show(
				[PowerShellTypeExtensions.Win32Window]::CurrentWindow,
				$Text,
				$Caption,
				$Buttons,
				$Icon,
				$DefaultButton,
				$Options
			)
		} elseif ($Buttons -ne [System.Windows.Forms.MessageBoxButtons]::OK) {
			[System.Int32]$defaultChoice = ([System.Int32]$DefaultButton) / 256
			[System.Management.Automation.Host.ChoiceDescription[]]$choices = @()
			[System.Collections.Hashtable]$resultMap = @{}
			if ($Buttons -eq [System.Windows.Forms.MessageBoxButtons]::AbortRetryIgnore) {
				$choices = @('Abort','Retry','Ignore')
				$resultMap = @{
					0 = [System.Windows.Forms.DialogResult]::Abort
					1 = [System.Windows.Forms.DialogResult]::Retry
					2 = [System.Windows.Forms.DialogResult]::Ignore
				}
			} elseif ($Buttons -eq [System.Windows.Forms.MessageBoxButtons]::OKCancel) {
				$choices = @('OK','Cancel')
				$resultMap = @{
					0 = [System.Windows.Forms.DialogResult]::OK
					1 = [System.Windows.Forms.DialogResult]::Cancel
				}
			} elseif ($Buttons -eq [System.Windows.Forms.MessageBoxButtons]::RetryCancel) {
				$choices = @('Retry','Cancel')
				$resultMap = @{
					0 = [System.Windows.Forms.DialogResult]::Retry
					1 = [System.Windows.Forms.DialogResult]::Cancel
				}
			} elseif ($Buttons -eq [System.Windows.Forms.MessageBoxButtons]::YesNo) {
				$choices = @('Yes','No')
				$resultMap = @{
					0 = [System.Windows.Forms.DialogResult]::Yes
					1 = [System.Windows.Forms.DialogResult]::No
				}
			} elseif ($Buttons -eq [System.Windows.Forms.MessageBoxButtons]::YesNoCancel) {
				$choices = @('Yes','No','Cancel')
				$resultMap = @{
					0 = [System.Windows.Forms.DialogResult]::Yes
					1 = [System.Windows.Forms.DialogResult]::No
					2 = [System.Windows.Forms.DialogResult]::Cancel
				}
			}
			if (-not $resultMap.ContainsKey($defaultChoice)) {
				$defaultChoice = 0
			}
			$result = $Host.UI.PromptForChoice($Caption,$Text,$choices,$defaultChoice)
			$resultMap[$result]
		} else {
			Write-Host $Text
			[System.Windows.Forms.DialogResult]::OK
		}
	}
	catch {
		throw
	}
}

#endregion
#region Core Utility Functions

function global:Get-PSResourceString {
	param(
		[string]$BaseName = $null,
		[string]$ResourceId = $null,
		[string]$DefaultValue = $null,
		[System.Globalization.CultureInfo]$Culture = $host.CurrentCulture,
		[Switch]$List
	)

	if ($List -and ($ResourceId -or $DefaultValue)) {
		throw $(Get-PSResourceString -BaseName 'ParameterBinderStrings' -ResourceId 'AmbiguousParameterSet')
	}

	if ($List) {
		$engineAssembly = [System.Reflection.Assembly]::GetExecutingAssembly()
		$hostAssembly = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.PowerShell.ConsoleHost')
		if ($BaseName) {
			$engineAssembly.GetManifestResourceNames() | Where-Object { $_ -eq "$BaseName.resources" } | ForEach-Object {
				$resourceManager = New-Object -TypeName System.Resources.ResourceManager($BaseName, $engineAssembly)
				$resourceManager.GetResourceSet($host.CurrentCulture,$true,$true) | Add-Member -Name BaseName -MemberType NoteProperty -Value $BaseName -Force -PassThru | ForEach-Object {
					$_.PSObject.TypeNames.Clear()
					$_.PSObject.TypeNames.Add('ResourceString')
					$_ | Write-Output
				}
			}
			$hostAssembly.GetManifestResourceNames() | Where-Object { $_ -eq "$BaseName.resources" } | ForEach-Object {
				$resourceManager = New-Object -TypeName System.Resources.ResourceManager($BaseName, $hostAssembly)
				$resourceManager.GetResourceSet($host.CurrentCulture,$true,$true) | Add-Member -Name BaseName -MemberType NoteProperty -Value $BaseName -Force -PassThru | ForEach-Object {
					$_.PSObject.TypeNames.Clear()
					$_.PSObject.TypeNames.Add('ResourceString')
					$_ | Write-Output
				}
			}
		} else {
			$engineAssembly.GetManifestResourceNames() | Where-Object { $_ -match '\.resources$' } | ForEach-Object { $_.Replace('.resources','') }
			$hostAssembly.GetManifestResourceNames() | Where-Object { $_ -match '\.resources$' } | ForEach-Object { $_.Replace('.resources','') }
		}
	} else {
		if (-not $BaseName) {
			throw $($(Get-PSResourceString -BaseName 'ParameterBinderStrings' -ResourceId 'ParameterArgumentValidationErrorNullNotAllowed') -f $null,'BaseName')
		}
		if (-not $ResourceId) {
			throw $($(Get-PSResourceString -BaseName 'ParameterBinderStrings' -ResourceId 'ParameterArgumentValidationErrorNullNotAllowed') -f $null,'ResourceId')
		}
		if (-not $global:PSResourceStringTable) {
			$engineAssembly = [System.Reflection.Assembly]::GetExecutingAssembly()
			$hostAssembly = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.PowerShell.ConsoleHost')
			if ($engineAssembly.GetManifestResourceNames() -contains "$BaseName.resources") {
				New-Variable -Scope Global -Name PSResourceStringTable -Value @{} -Description 'A cache of PowerShell resource strings. To access data in this table, use Get-ResourceString.'
				$global:PSResourceStringTable['EngineAssembly'] = @{'Assembly'=$engineAssembly;'Cultures'=@{}}
				$global:PSResourceStringTable['HostAssembly'] = @{'Assembly'=$hostAssembly;'Cultures'=@{}}
				$resourceManager = (New-Object -TypeName System.Resources.ResourceManager($BaseName, $global:PSResourceStringTable.EngineAssembly.Assembly));
				$global:PSResourceStringTable.EngineAssembly.Cultures[$Culture.Name] = @{$BaseName=@{'ResourceManager'=$resourceManager;'Strings'=$resourceManager.GetResourceSet($Culture,$true,$true)}};
			} elseif ($hostAssembly.GetManifestResourceNames() -contains "$BaseName.resources") {
				New-Variable -Scope Global -Name PSResourceStringTable -Value @{} -Description 'A cache of PowerShell resource strings. To access data in this table, use Get-ResourceString.'
				$global:PSResourceStringTable['EngineAssembly'] = @{'Assembly'=$engineAssembly;'Cultures'=@{}}
				$global:PSResourceStringTable['HostAssembly'] = @{'Assembly'=$hostAssembly;'Cultures'=@{}}
				$resourceManager = (New-Object -TypeName System.Resources.ResourceManager($BaseName, $global:PSResourceStringTable.HostAssembly.Assembly));
			$global:PSResourceStringTable.HostAssembly.Cultures[$Culture.Name] = @{$BaseName=@{'ResourceManager'=$resourceManager;'Strings'=$resourceManager.GetResourceSet($Culture,$true,$true)}};
			}
		} elseif ($global:PSResourceStringTable.EngineAssembly.Assembly.GetManifestResourceNames() -contains "$BaseName.resources") {
			if (-not $global:PSResourceStringTable.EngineAssembly.Cultures.ContainsKey($Culture.Name)) {
				$resourceManager = (New-Object -TypeName System.Resources.ResourceManager($BaseName, $global:PSResourceStringTable.EngineAssembly.Assembly));
				$global:PSResourceStringTable.EngineAssembly.Cultures[$Culture.Name] = @{$BaseName=@{'ResourceManager'=$resourceManager;'Strings'=$resourceManager.GetResourceSet($Culture,$true,$true)}};
			} elseif (-not $global:PSResourceStringTable.EngineAssembly.Cultures[$Culture.Name].ContainsKey($BaseName)) {
				$resourceManager = (New-Object -TypeName System.Resources.ResourceManager($BaseName, $global:PSResourceStringTable.EngineAssembly.Assembly));
				$global:PSResourceStringTable.EngineAssembly.Cultures[$Culture.Name][$BaseName] = @{'ResourceManager'=$resourceManager;'Strings'=$resourceManager.GetResourceSet($Culture,$true,$true)};
			}
		} elseif ($global:PSResourceStringTable.HostAssembly.Assembly.GetManifestResourceNames() -contains "$BaseName.resources") {
			if (-not $global:PSResourceStringTable.HostAssembly.Cultures.ContainsKey($Culture.Name)) {
				$resourceManager = (New-Object -TypeName System.Resources.ResourceManager($BaseName, $global:PSResourceStringTable.HostAssembly.Assembly));
				$global:PSResourceStringTable.HostAssembly.Cultures[$Culture.Name] = @{$BaseName=@{'ResourceManager'=$resourceManager;'Strings'=$resourceManager.GetResourceSet($Culture,$true,$true)}};
			} elseif (-not $global:PSResourceStringTable.HostAssembly.Cultures[$Culture.Name].ContainsKey($BaseName)) {
				$resourceManager = (New-Object -TypeName System.Resources.ResourceManager($BaseName, $global:PSResourceStringTable.HostAssembly.Assembly));
				$global:PSResourceStringTable.HostAssembly.Cultures[$Culture.Name][$BaseName] = @{'ResourceManager'=$resourceManager;'Strings'=$resourceManager.GetResourceSet($Culture,$true,$true)};
			}
		}

		$resourceString = $null
		if ($global:PSResourceStringTable) {
			if ($global:PSResourceStringTable.EngineAssembly.Cultures -and $global:PSResourceStringTable.EngineAssembly.Cultures.ContainsKey($Culture.Name) -and $global:PSResourceStringTable.EngineAssembly.Cultures[$Culture.Name].ContainsKey($BaseName)) {
				$resourceString = ($global:PSResourceStringTable.EngineAssembly.Cultures[$Culture.Name][$BaseName].Strings | Where-Object { $_.Name -eq $ResourceId }).Value
			} elseif ($global:PSResourceStringTable.HostAssembly.Cultures -and $global:PSResourceStringTable.HostAssembly.Cultures.ContainsKey($Culture.Name) -and $global:PSResourceStringTable.HostAssembly.Cultures[$Culture.Name].ContainsKey($BaseName)) {
				$resourceString = ($global:PSResourceStringTable.HostAssembly.Cultures[$Culture.Name][$BaseName].Strings | Where-Object { $_.Name -eq $ResourceId }).Value
			}
		}
		if (-not $resourceString) {
			$resourceString = $DefaultValue
		}
		
		return $resourceString
	}
}

function global:New-Enum {
	param(
		[string]$Name = $null,
		[string]$AssemblyName = $null,
		[System.Management.Automation.PSObject]$Values = $null
	)

	$internalScript = {
		param(
			[string]$Name = $null,
			[string]$AssemblyName = $null,
			[System.Management.Automation.PSObject]$Values = $null
		)

		$promptedForRequiredParameters = $false
		if ((-not $promptedForRequiredParameters) -and ((-not $Name) -or ((-not $Values) -and (-not $Values.Count) -and (-not $Values.Keys.Count)))) {
			$promptedForRequiredParameters = $true
			Write-Host -ForegroundColor White -Object ((Get-PSResourceString -BaseName ParameterBinderStrings -ResourceId PromptCaption) -f 'New-Enum',$MyInvocation.PipelinePosition)
			Write-Host (Get-PSResourceString -BaseName -ResourceId PromptMessage)
			if (-not $Name) {
				if ($result = Read-Host -Prompt 'Name') {
					$Name = $result
				} else {
					return
				}
			}
			if (-not $Values) {
				$index = 0
				$Values = @()
				while ($result = Read-Host -Prompt "Values[$index]") {
					$index++
					$Values += $result
				}
				if (-not $Values) {
					return
				}
			}
		}

		$appdomain = [System.Threading.Thread]::GetDomain()
		$assembly = New-Object -TypeName System.Reflection.AssemblyName
		if ($AssemblyName) {
			$assembly.Name = $AssemblyName
			$Name = "$AssemblyName.$Name"
		} else {
			$assembly.Name = 'DynamicallyCreatedEnum'
		}

		$assemblyBuilder = $appdomain.DefineDynamicAssembly(
			$assembly,
			[System.Reflection.Emit.AssemblyBuilderAccess]::Save -bor [System.Reflection.Emit.AssemblyBuilderAccess]::Run
		)

		$moduleBuilder = $assemblyBuilder.DefineDynamicModule("DynamicModule", "DynamicModule.mod")

		$enumBuilder = $moduleBuilder.DefineEnum($Name, [System.Reflection.TypeAttributes]::Public, [int32])

		if (($Values -is [string]) -or ($Values -is [array])) {
			$Values = @($Values) + $args
			for ($i = 0; $i -lt $Values.Length; $i++) {
				$enumBuilder.DefineLiteral($Values[$i],$i) | Out-Null
			}
		} elseif ($Values -is [System.Collections.Hashtable]) {
			foreach ($key in $Values.Keys) {
				$enumBuilder.DefineLiteral($key,$Values[$key]) | Out-Null
			}
		}

		$enumBuilder.CreateType()
	}

	#region Extra script to workaround PowerShell v2 defect.
	$passThruArgs = $args
	$trailingArguments = ''
	for ($index = 0; $index -lt $passThruArgs.Count; $index++) {
		$trailingArguments += " `$passThruArgs[$index]"
	}
	Invoke-Expression "& `$internalScript -Name `$Name -AssemblyName `$AssemblyName -Values `$Values$trailingArguments | Out-Null"
	Invoke-Expression "& `$internalScript -Name `$Name -AssemblyName `$AssemblyName -Values `$Values$trailingArguments"
	#endregion
}

#endregion
#region Read Input Functions

function global:New-ChoiceDescription {
	param(
		[string]$Name,
		[string]$HelpMessage = $null
	)

	$choiceDescription = [System.Management.Automation.Host.ChoiceDescription]$Name
	$choiceDescription.HelpMessage = $HelpMessage

	$choiceDescription
}

function global:Read-Choice {
	param(
		[string]$Caption,
		[string]$Message,
		[System.Management.Automation.Host.ChoiceDescription[]]$ChoiceDescription,
		[int]$DefaultChoice = 0
	)

	$host.ui.PromptForChoice($Caption,$Message,$ChoiceDescription,$DefaultChoice)
}

function global:New-FieldDescription {
	param(
		[string]$Name,
		[string]$HelpMessage = $null,
		[Type]$Type = 'System.String',
		[PSObject]$DefaultValue = $null,
		[bool]$IsMandatory = $false
	)

	$fieldDescription = [System.Management.Automation.Host.FieldDescription]$Name
	$fieldDescription.SetParameterType([Type]$Type)
	$fieldDescription.DefaultValue = $DefaultValue
	$fieldDescription.HelpMessage = $HelpMessage
	$fieldDescription.IsMandatory = $IsMandatory

	$fieldDescription
}

function global:Read-Input {
	param(
		[string]$Caption,
		[string]$Message,
		[System.Management.Automation.Host.FieldDescription[]]$FieldDescription
	)

	$host.ui.Prompt($Caption,$Message,$FieldDescription)
}

function global:New-Credential {
	param(
		[string]$Username,
		[System.Security.SecureString]$Password
	)
	
	New-Object System.Management.Automation.PSCredential($Username,$Password)
}

function global:Read-Credential {
	param(
		$Credential = $null
	)

	if ($Credential -is [System.Management.Automation.PSCredential]) {
		$Credential
	} else {
		$result = Read-Input 'Enter your credentials' 'Please enter your authentication credentials in the fields provided' @((New-FieldDescription 'Username' 'Your account username' 'System.String' $Credential $true),(New-FieldDescription 'Password' 'Your account password' 'System.Security.SecureString' $null $true))
		if ($result.Count) {
			New-Credential -Username $result['Username'] -Password $result['Password']
		}
	}
}

#endregion
#region Admin Console Functions

function global:Get-AdminConsoleName {
	if ($Host.PrivateData.ProductTitle) {
		$Host.PrivateData.ProductTitle
	} else {
		$currentNode = $Host.PrivateData.ConsoleHostFactory.Application.Navigation.CurrentItem
		while ($currentNode.Type -ne 'Root') {
			$currentNode = $currentNode.Parent
		}
		$currentNode.Name
	}
}

function global:Get-AdminConsoleViewName {
	$Host.PrivateData.ConsoleHostFactory.Application.Navigation.LinkLabel
}

#endregion
#region HTML Report Functions

function global:New-HtmlReport {
	param(
		[string]      $Title,
		[string]      $Filename    = "$($env:TEMP)\$(if (Get-Item -Path Function::Get-AdminConsoleName -Erroraction SilentlyContinue) {(Get-AdminConsoleName) -replace '[\s\[\]]',''} else {'PowerShell'})Report_$(Get-Date -Format hhmmss_ddMMyyyy).htm",
		[switch]      $OpenFile,
		[switch]      $OpenFolder,
		[PSObject]    $Content     = $null
	)
	[string]                     $reportContents = $null
	[string]                     $html           = $null
	[string]                     $htmFilePath    = $null
	[System.Diagnostics.Process] $process        = $null

	if ($Content) {
		if ($Content -is [ScriptBlock]) {
			& $Content | ForEach-Object {
				$reportContents += [string]$_
			}
			$reportContents.Trim("`n")
		} else {
			$reportContents = [string]$Content
		}
		$reportContents = $reportContents.Trim()
	}

	$h2background ="#ad1c18"
	$h3background = "#ADADAD"
			
	if (Get-Item -Path Function::Get-AdminConsoleName -Erroraction SilentlyContinue) { 
		if ((Get-AdminConsoleName) -match "EcoShell") {
			$h2background = "#8DC63F"
			$h3background = "#A5A5A5"
		} 
	}
	
	function Get-TableCssSettings {
		param(
			[string] $Display    = 'none',
			[UInt16] $LeftIndent = 16,
			[switch] $Frame
		)
		@"
    display: $Display;
    position: relative;
    color: #000000;
$(if ($Frame) {
	@'
    background-color: #f9f9f9;
    border-left: #b1babf 1px solid;
    border-right: #b1babf 1px solid;
    border-top: #b1babf 1px solid;
    border-bottom: #b1babf 1px solid;
'@
})
    padding-left: ${LeftIndent}px;
    padding-top: 4px;
    padding-bottom: 5px;
    margin-left: 0px;
    margin-right: 0px;
    margin-bottom: 0px;
"@
	}
	function Get-TableTitleCssSettings {
		param(
			[string] $BackgroundColor = '#0061bd'
		)
		@"
    display: block;
    position: relative;
    height: 2em;
    color: #ffffff;
    background-color: $BackgroundColor;
    border-left: #b1babf 1px solid;
    border-right: #b1babf 1px solid;
    border-top: #b1babf 1px solid;
    border-bottom: #b1babf 1px solid;
    padding-left: 5px;
    padding-top: 8px;
    margin-left: 0px;
    margin-right: 0px;
    font-family: Tahoma;
    font-size: 8pt;
    font-weight: bold;
"@
	}
	function Get-SpanCssSettings {
		@"
    display: block;
    position: absolute;
    color: #ffffff;
    top: 8px;
    font-family: Tahoma;
    font-size: 8pt;
    font-weight: bold;
    text-decoration: underline;
"@
	}
	$html = @"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
<html>
<head>
<title>$Title</title>
<meta http-equiv=Content-Type content='text/html; charset=windows-1252'></meta>
<meta name="save" content="history"></meta>
<style type="text/css">
body {
    margin-left: 4pt;
    margin-right: 4pt;
    margin-top: 6pt;
    font-family: Tahoma;
    font-size: 8pt;
    font-weight: normal;
}
h1 {
$(Get-TableTitleCssSettings -BackgroundColor '#0061bd')
}
h2 {
$(Get-TableTitleCssSettings -BackgroundColor $h2background)
}
h3 {
$(Get-TableTitleCssSettings -BackgroundColor $h3background)
}
span.expandableHeaderLink {
$(Get-SpanCssSettings)
}
span.expandableHeaderLinkRightJustified {
$(Get-SpanCssSettings)
    right: 8px;
}
table {
    table-layout: fixed;
    font-size: 100%;
    width: 100%;
    color: #000000;
}
th {
    color: #0061bd;
    padding-top: 2px;
    padding-bottom: 2px;
    vertical-align: top;
    text-align: left;
}
td {
    padding-top: 2px;
    padding-bottom: 2px;
    vertical-align: top;
}
*{margin:0}
div.visibleSection {
$(Get-TableCssSettings -Display 'block' -Frame)
}
div.hiddenSection {
$(Get-TableCssSettings -Display 'none' -Frame)
}
div.visibleSectionNoIndent {
$(Get-TableCssSettings -Display 'block' -LeftIndent 0 -Frame)
}
div.hiddenSectionNoIndent {
$(Get-TableCssSettings -Display 'none' -LeftIndent 0 -Frame)
}
div.visibleSectionNoFrame {
$(Get-TableCssSettings -Display 'block' -LeftIndent 0)
}
div.hiddenSectionNoFrame {
$(Get-TableCssSettings -Display 'none' -LeftIndent 0)
}
div.filler {
    display: block;
    position: relative;
    color: #ffffff;
    background: none transparent scroll repeat 0% 0%;
    border-left: medium none;
    border-right: medium none;
    border-top: medium none;
    border-bottom: medium none;
    padding-top: 4px;
    margin-left: 0px;
    margin-right: 0px;
    margin-bottom: -1px;
    font: 100%/8px Tahoma;
}
div.save {
    behavior: url(#default#savehistory);
}
</style>
<script type="text/javascript">
function toggleVisibility(tableHeader) {
    if (document.getElementById) {
        var triggerLabel = tableHeader.firstChild;
        while ((triggerLabel) && (triggerLabel.innerHTML != 'show') && (triggerLabel.innerHTML != 'hide')) {
            triggerLabel = triggerLabel.nextSibling
        }
        if (triggerLabel) {
            triggerLabel.innerHTML = (triggerLabel.innerHTML == 'hide' ? 'show' : 'hide');
            associatedTable = tableHeader.nextSibling
            while ((associatedTable) && (!(associatedTable.style))) {
                associatedTable = associatedTable.nextSibling
            }
            if (associatedTable) {
                associatedTable.style.display = (triggerLabel.innerHTML == 'hide' ? 'block' : 'none');
            }
        }
    }
}
if (!document.getElementById) {
    document.write('<style type="text/css">\n'+'\tdiv.hiddenSection {\n\t\tdisplay:block;\n\t}\n'+ '</style>');
}
</script>
</head>
<body>
<b><font face="Arial" size="5">$Title</font></b>
<hr size="8" color="#0061bd"></hr>
<font face="Arial" size="1"><b>Generated with $(if (Get-Item -Path Function::Get-AdminConsoleName -Erroraction SilentlyContinue) {Get-AdminConsoleName} else {'PowerShell'})</b></font>
<br />
<font face="Arial" size="1">Report created on $(Get-Date)</font>
<div class="filler"></div>
<div class="filler"></div>
<div class="filler"></div>
<div class="save">
$reportContents
</div>
</body>
</html>
"@
	if (-not $Filename) {
		$Filename = "$($env:TEMP)\$(if (Get-Item -Path Function::Get-AdminConsoleName -Erroraction SilentlyContinue) {(Get-AdminConsoleName) -replace '[\s\[\]]',''} else {'PowerShell'})Report_$(Get-Date -Format hhmmss_ddMMyyyy).htm"
	}
	$html | Out-File -Encoding Unicode -FilePath $Filename
	$htmFilePath = (Get-Item -LiteralPath $Filename -ErrorAction SilentlyContinue).PSPath
	if (-not $htmFilePath) {
		throw "File '$Filename' was not created"
	}
	if ($OpenFile) {
		if (Test-Path -LiteralPath "Registry::HKEY_CLASSES_ROOT\.htm" -ErrorAction SilentlyContinue) {
			Invoke-Item -LiteralPath $htmFilePath
		} else {
			$process = New-Object System.Diagnostics.Process
			$process.StartInfo.Filename = 'notepad.exe'
			$process.StartInfo.Arguments = "`"$($htmFilePath.Replace('Microsoft.PowerShell.Core\FileSystem::',''))`""
			if (-not $process.Start()) { 
				throw 'Unable to launch notepad.exe'
			}
		}
	}
	if ($OpenFolder) {
		$process = New-Object System.Diagnostics.Process
		$process.StartInfo.Filename = 'explorer.exe'
		$process.StartInfo.Arguments = "/select,`"$($htmFilePath.Replace('Microsoft.PowerShell.Core\FileSystem::',''))`""
		if (-not $process.Start()) { 
			throw 'Unable to launch explorer.exe'
		}
	}
	Get-Item -LiteralPath $htmFilePath
}

function global:Add-HtmlReportSeparator {
	@"
<hr />
"@
}

function global:Add-HtmlReportSubtitle {
	param(
		$Subtitle = $null
	)
	@"
<table>
<th><u>$Subtitle</u></th>
</table>
"@
}

function global:Add-HtmlReportSection {
	param(
		[string]   $Title         = $null,
		[UInt16]   $Level         = 1,
		[switch]   $NoIndent,
		[switch]   $NoFrame,
		[switch]   $Collapsible,
		[switch]   $Expanded,
		[PSObject] $Content       = $null
	)
	[UInt16] $headingLevel   = $(if (@(1,2,3) -notcontains $Level) {3} else {$Level})
	[string] $sectionClass   = 'visibleSection'
	[string] $reportContents = $null

	if ($Title) {
		if ($Collapsible) {
			if (-not $Expanded) {
				$sectionClass = 'hiddenSection'
			}
			@"
<h$headingLevel style="cursor: pointer" onclick="toggleVisibility(this)">
<span class="expandableHeaderLink">$Title</span>
<span class="expandableHeaderLinkRightJustified">$(if ($Expanded) {'hide'} else {'show'})</span>
</h$headingLevel>
"@
		} else {
			@"
<h$headingLevel>
$Title
</h$headingLevel>
"@
		}
	}
	if ($Content) {
		if ($Content -is [ScriptBlock]) {
			& $Content | ForEach-Object {
				$reportContents += [string]$_
			}
			$reportContents = $reportContents.Trim("`n")
		} else {
			$reportContents = [string]$Content
		}
		$reportContents = $reportContents.Trim()
		if ($NoFrame) {
			@"
<div class="${sectionClass}NoFrame">
$reportContents
</div>
"@
		} elseif ($NoIndent) {
			@"
<div class="${sectionClass}NoIndent">
$reportContents
</div>
"@
		} else {
			@"
<div class="$sectionClass">
$reportContents
</div>
"@
		}
	}
	@"
<div class="filler"></div>
"@		
}

function global:ConvertTo-HtmlReportTable {
	param(
		[PSObject] $InputObject       = $null,
		[String[]] $Property          = $null,
		[String[]] $GroupBy           = $null,
		[string]   $Title             = $null,
		[UInt16]   $Level             = 1,
		[string]   $Indent            = 'AllLevels',
		[switch]   $PrefixGroupNames,
		[switch]   $Collapsible,
		[switch]   $Expanded,
		[PSObject] $AdditionalContent = $null
	)
	begin {
		[PSObject] $processObject    = $null
		[array]    $objectCollection = @()
		[String[]] $innerHtml        = @()
		[string]   $groupNamePrefix  = $null
		[string]   $groupTitle       = $null
		[string]   $html             = $null

		if (@('None','OneLevel','AllLevels') -notcontains $Indent) {
			throw "Cannot bind parameter ""Indent"". Specify one of the following values and try again. The possible values are ""None"", ""OneLevel"", and ""AllLevels""."
			return
		}
	}
	process {
		if ($InputObject -and $_) {
			throw 'The input object cannot be bound to any parameters for the command either because the command does not take pipeline input or the input and its properties do not match any of the parameters that take pipeline input.'
			return
		}
		if ($processObject = $(if ($InputObject) {$InputObject} else {$_})) {
			$objectCollection += $processObject
		}
	}
	end {
		if ($GroupBy) {
			$innerHtml = $objectCollection | Group-Object -Property $GroupBy[0] | ForEach-Object {
				$groupNamePrefix = $null
				if ($PrefixGroupNames) {
					$groupNamePrefix = "$($GroupBy[0]): "
				}
				$groupTitle = $(if ($_.Name) {"$groupNamePrefix$($_.Name)"} else {"$groupNamePrefix<i>Value not set</i>"})
				$_.Group | ConvertTo-HtmlReportTable -Property $Property -GroupBy $(if ($GroupBy.Count -gt 1) {$GroupBy[1..$($GroupBy.Count - 1)]} else {$null}) -Title $groupTitle -Level ($Level + 1) -Indent $(if ($Indent -eq 'OneLevel') {'None'} else {$Indent}) -PrefixGroupNames:$PrefixGroupNames -Collapsible -Expanded:$Expanded
			}
			if (-not $innerHtml) {
				$innerHtml = @()
			}
			$html = [string]::Join("`n",$innerHtml)
		} else {
			if ($Property) {
				$innerHtml = $objectCollection | ConvertTo-Html -Property $Property
			} elseif ($objectCollection.Count -and ($objectCollection[0].GetType().IsPrimitive -or ($objectCollection[0] -is [System.String]))) {
				$innerHtml = $objectCollection | ConvertTo-Html -Property @{label='Value';expression={$_}}
			} else {
				$innerHtml = $objectCollection | ConvertTo-Html
			}
			if (-not $innerHtml) {
				$innerHtml = @()
			}
			$html = [string]::Join("`n",$innerHtml) -replace '(?s).*(<table>.*</table>).*','$1' -replace "<col>`n","<col></col>`n"
		}
		if ($AdditionalContent) {
			if ($AdditionalContent -is [ScriptBlock]) {
				$html += & $AdditionalContent
			} else {
				$html += [string]$AdditionalContent
			}
		}
		Add-HtmlReportSection -Title $Title -Level $Level -NoIndent:$($Indent -eq 'None') -Collapsible:$Collapsible -Expanded:$Expanded -Content $html
	}
}

function global:ConvertTo-HtmlReportList {
	param(
		[PSObject] $InputObject       = $null,
		[String[]] $Property          = $null,
		[String[]] $GroupBy           = $null,
		[string]   $Title             = $null,
		[UInt16]   $Level             = 1,
		[string]   $Indent            = 'AllLevels',
		[switch]   $PrefixGroupNames,
		[switch]   $Collapsible,
		[switch]   $Expanded,
		[PSObject] $AdditionalContent = $null
	)
	begin {
		[PSObject] $processObject    = $null
		[array]    $objectCollection = @()
		[String[]] $innerHtml        = @()
		[string]   $groupNamePrefix  = $null
		[string]   $groupTitle       = $null
		[string]   $html             = $null
		[UInt32]   $index            = 0
		[string]   $itemHtml         = $null

		if (@('None','OneLevel','AllLevels') -notcontains $Indent) {
			throw "Cannot bind parameter ""Indent"". Specify one of the following values and try again. The possible values are ""None"", ""OneLevel"", and ""AllLevels""."
			return
		}
	}
	process {
		if ($InputObject -and $_) {
			throw 'The input object cannot be bound to any parameters for the command either because the command does not take pipeline input or the input and its properties do not match any of the parameters that take pipeline input.'
			return
		}
		if ($processObject = $(if ($InputObject) {$InputObject} else {$_})) {
			$objectCollection += $processObject
		}
	}
	end {
		if ($GroupBy) {
			$innerHtml = $objectCollection | Group-Object -Property $GroupBy[0] | ForEach-Object {
				$groupNamePrefix = $null
				if ($PrefixGroupNames) {
					$groupNamePrefix = "$($GroupBy[0]): "
				}
				$groupTitle = $(if ($_.Name) {"$groupNamePrefix$($_.Name)"} else {"$groupNamePrefix<i>Value not set</i>"})
				$_.Group | ConvertTo-HtmlReportList -Property $Property -GroupBy $(if ($GroupBy.Count -gt 1) {$GroupBy[1..$($GroupBy.Count - 1)]} else {$null}) -Title $groupTitle -Level ($Level + 1) -Indent $(if ($Indent -eq 'OneLevel') {'None'} else {$Indent}) -PrefixGroupNames:$PrefixGroupNames -Collapsible -Expanded:$Expanded
			}
			if (-not $innerHtml) {
				$innerHtml = @()
			}
			$html = [string]::Join("`n",$innerHtml)
		} else {
			$innerHtml = $(for ($index = 0; $index -lt $objectCollection.Count; $index++) {
				$itemHtml = $(foreach ($item in $(if ($Property) {$Property} else {$objectCollection[$index].PSObject.Properties | Where-Object {$_.IsGettable} | ForEach-Object {$_.Name}})) {
					@"
<tr>
<th width='25%'><b>${item}:</b></th>
<td width='75%'>$([string]($objectCollection[$index].$item))</td>
</tr>
"@
				})
				if ($index -eq ($objectCollection.Count - 1)) {
					$itemHtml
				} else {
					@"
$itemHtml
</table>
$(Add-HtmlReportSeparator)
<table>
"@
				}
			})
			if (-not $innerHtml) {
				$innerHtml = @()
			}
			$html = @"
<table>
$([string]::Join("`n",$innerHtml))
</table>
"@
		}
		if ($AdditionalContent) {
			if ($AdditionalContent -is [ScriptBlock]) {
				$html += & $AdditionalContent
			} else {
				$html += [string]$AdditionalContent
			}
		}
		Add-HtmlReportSection -Title $Title -Level $Level -NoFrame:$($Indent -eq 'None') -Collapsible:$Collapsible -Expanded:$Expanded -Content $html
	}
}

#endregion
#region Create enumerations used by the reporting engine.

if (-not (Get-Variable 'AdminConsoleEnum' -Scope Global -ErrorAction SilentlyContinue)) {
	$global:AdminConsoleEnum = @{}
}
if ($global:AdminConsoleEnum.Keys -notcontains 'ReportIndentationStyle') {
	$global:AdminConsoleEnum['ReportIndentationStyle'] = New-Enum -Name 'ReportIndentationStyle' -AssemblyName 'AdminConsole' -Values 'None' 'One level' 'All levels'
}
if ($global:AdminConsoleEnum.Keys -notcontains 'ReportDataFormat') {
	$global:AdminConsoleEnum['ReportDataFormat'] = New-Enum -Name 'ReportDataFormat' -AssemblyName 'AdminConsole' -Values 'Automatic (format chosen based on the number of properties selected)' 'Table' 'List'
}

#endregion