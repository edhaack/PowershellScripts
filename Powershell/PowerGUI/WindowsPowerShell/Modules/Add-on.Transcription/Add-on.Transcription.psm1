#######################################################################################################################
# File:             Add-on.Transcription.psm1                                                                         #
# Author:           Kirk Munro                                                                                        #
# Publisher:        Quest Software, Inc.                                                                              #
# Copyright:        © 2010 Quest Software, Inc.. All rights reserved.                                                 #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   3. Check the Add-on.Transcription module.                                                         #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this:                 #
#                       Import-Module -Name Add-on.Transcription                                                      #
#                   Please provide feedback on the PowerGUI Forums.                                                   #
#######################################################################################################################

Set-StrictMode -Version 2

#region Initialize the Script Editor Add-on.

if ($Host.Name –ne 'PowerGUIScriptEditorHost') { return }
if ($Host.Version -lt '2.1.0.1200') {
	[System.Windows.Forms.MessageBox]::Show("The ""$(Split-Path -Path $PSScriptRoot -Leaf)"" Add-on module requires version 2.1.0.1200 or later of the Script Editor. The current Script Editor version is $($Host.Version).$([System.Environment]::NewLine * 2)Please upgrade to version 2.1.0.1200 and try again.","Version 2.1.0.1200 or later is required",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
	return
}

$se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

#endregion

#region Define helper variables.

[Hashtable]$ResourceStringTable = @{}
[Hashtable]$script:TranscriptConfiguration = @{}
[int]$script:LastCaretPosition = 0

#endregion

#region Define .NET Types.

if (-not ('Transcription.HostTextWriter' -as [System.Type])) {
	$cSharpCode = @'
using System;
using System.IO;
using System.Text;
using System.Windows.Forms;

namespace Transcription
{
    public class HostTextWriter
    {
        private readonly object _syncRoot = new object();
        private int _offset;
        private string _path;
        private RichTextBox _powerShellConsole;

        private delegate void Action();

        public void StartTranscript(string path, RichTextBox powerShellConsole)
        {
            try
            {
                lock (_syncRoot)
                {
                    _path = path;
                    _powerShellConsole = powerShellConsole;
                    _powerShellConsole.BeginInvoke(new Action(InitPowerShellConsole));
                }
                
            }
            catch (Exception ex)
            {
                ReportError(ex);
            }
        }

        public void WriteLine(string text, string path)
        {
            lock (_syncRoot)
            {
                if (!string.IsNullOrEmpty(text))
                {
                    StreamWriter writer = new StreamWriter(!string.IsNullOrEmpty(path) ? path : _path, true, Encoding.Unicode);
                    writer.AutoFlush = true;
                    try
                    {
                        writer.WriteLine(text);
                    }
                    catch (Exception ex)
                    {
                        ReportError(ex);
                    }
                    finally
                    {
                        writer.Close();
                    }
                }
            }
        }

        public void StopTranscript()
        {
            try
            {
                lock (_syncRoot)
                {
                    _powerShellConsole.TextChanged -= OnTextChanged;
                }
                
            }
            catch (Exception ex)
            {

                ReportError(ex);
            }
        }
        
        private void InitPowerShellConsole()
        {
            _offset = _powerShellConsole.TextLength;
            _powerShellConsole.TextChanged += OnTextChanged;
        }

        private void ReportError(Exception ex)
        {
            MessageBox.Show(ex.ToString(), "Error");
        }

        private void OnTextChanged(object sender, EventArgs args)
        {
            if (_powerShellConsole.Text.Length < _offset)
            {
                return;
            }

            WriteLine(_powerShellConsole.Text.Substring(_offset), null);
        }
    }
}
'@

Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition $cSharpCode	

}

$HostTextWriter = New-Object -TypeName Transcription.HostTextWriter

#endregion

#region Define private functions.

function Get-ResourceString {
	[OutputType([System.String])]
	[OutputType('ResourceString', ParameterSetName='List')]
	[CmdletBinding(DefaultParameterSetName='Default')]
	param(
		[Parameter(ParameterSetName='Default', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[Parameter(ParameterSetName='List', Position=0, ValueFromPipeline=$true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		${BaseName},

		[Parameter(ParameterSetName='Default', Position=1, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		${ResourceId},

		[Parameter(ParameterSetName='Default', Position=2)]
		[ValidateNotNull()]
		[System.Globalization.CultureInfo]
		${Culture} = $host.CurrentCulture,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[System.String[]]
		${Assembly},

		[Parameter(ParameterSetName='List')]
		[ValidateSet($true)]
		[Switch]
		${List},

		[Parameter(ParameterSetName='List')]
		[Switch]
		${All}
	)

	begin {
		try {
			#region Get the required assemblies.
			if (-not $PSBoundParameters.ContainsKey('Assembly')) {
				$assemblies = @([System.Reflection.Assembly]::GetExecutingAssembly(), [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.PowerShell.ConsoleHost'))
			} else {
				$assemblies = @()
				foreach ($item in $Assembly) {
					if ($assemblyObject = [System.Reflection.Assembly]::LoadWithPartialName($item)) {
						$assemblies += $assemblyObject
					}
				}
			}
			#endregion
		}
		catch {
			throw
		}
	}
	process {
		try {
			switch ($PSCmdlet.ParameterSetName) {
				'List' {
					foreach ($item in $assemblies) {
						if ($PSBoundParameters.ContainsKey('BaseName')) {
							#region List all resources in the set identified by $BaseName.
							$item.GetManifestResourceNames() | Where-Object { $_ -eq "$BaseName.resources" } | ForEach-Object {
								$resourceManager = New-Object -TypeName System.Resources.ResourceManager($BaseName, $item)
								$resourceManager.GetResourceSet($host.CurrentCulture, $true, $true) `
									| Add-Member -Name BaseName -MemberType NoteProperty -Value $BaseName -Force -PassThru `
									| Select-Object -Property BaseName, @{name='ResourceId'; expression={$_.Key}}, @{name='ResourceString'; expression={$_.Value}} `
									| ForEach-Object {
										$_.PSObject.TypeNames.Clear()
										$_.PSObject.TypeNames.Add('ResourceString')
										$_
									}
							}
							#endregion
						} elseif ($PSBoundParameters.ContainsKey('All') -and $All) {
							#region List all resources in all sets.
							$item.GetManifestResourceNames() | Where-Object { $_ -match '\.resources$' } | ForEach-Object { $_.Replace('.resources','') } | Get-ResourceString -List
							#endregion
						} else {
							#region List all resource sets.
							$item.GetManifestResourceNames() | Where-Object { $_ -match '\.resources$' } | ForEach-Object { $_.Replace('.resources','') }
							#endregion
						}
					}
					break
				}
				'Default' {
					foreach ($item in $assemblies) {
						try
						{
							if (-not $ResourceStringTable.ContainsKey($item.FullName)) {
								#region Load the assembly resources into the resource table.
								if ($item.GetManifestResourceNames() -contains "$BaseName.resources") {
									$ResourceStringTable[$item.FullName] = @{'Assembly'=$item;'Cultures'=@{}}
									$resourceManager = (New-Object -TypeName System.Resources.ResourceManager($BaseName, $ResourceStringTable[$item.FullName].Assembly));
									$ResourceStringTable[$item.FullName].Cultures[$Culture.Name] = @{$BaseName=@{'ResourceManager'=$resourceManager;'Strings'=$resourceManager.GetResourceSet($Culture,$true,$true)}};
								}
								#endregion
							} else {
								#region Add the assembly resource strings to the resource table if they aren't loaded yet.
								if ($ResourceStringTable[$item.FullName].Assembly.GetManifestResourceNames() -contains "$BaseName.resources") {
									if (-not $ResourceStringTable[$item.FullName].Cultures.ContainsKey($Culture.Name)) {
										$resourceManager = (New-Object -TypeName System.Resources.ResourceManager($BaseName, $ResourceStringTable[$item.FullName].Assembly));
										$ResourceStringTable[$item.FullName].Cultures[$Culture.Name] = @{$BaseName=@{'ResourceManager'=$resourceManager;'Strings'=$resourceManager.GetResourceSet($Culture,$true,$true)}};
									} elseif (-not $ResourceStringTable[$item.FullName].Cultures[$Culture.Name].ContainsKey($BaseName)) {
										$resourceManager = (New-Object -TypeName System.Resources.ResourceManager($BaseName, $ResourceStringTable[$item.FullName].Assembly));
										$ResourceStringTable[$item.FullName].Cultures[$Culture.Name][$BaseName] = @{'ResourceManager'=$resourceManager;'Strings'=$resourceManager.GetResourceSet($Culture,$true,$true)};
									}
								}
								#endregion
							}

							#region Look up the resource string and return any matches that are found.
							if ($ResourceStringTable.ContainsKey($item.FullName) -and
						    	$ResourceStringTable[$item.FullName].ContainsKey('Cultures') -and
						    	$ResourceStringTable[$item.FullName].Cultures.ContainsKey($Culture.Name) -and
						    	$ResourceStringTable[$item.FullName].Cultures[$Culture.Name].ContainsKey($BaseName) -and
						    	($resourceString = ($ResourceStringTable[$item.FullName].Cultures[$Culture.Name][$BaseName].Strings | Where-Object { $_.Name -eq $ResourceId}).Value)) {
								$resourceString
							}
							#endregion
						}
						Catch [System.NotSupportedException]
						{
							
						}
						
					}

					break
				}
			}
		}
		catch {
			throw
		}
	}
}

#endregion

#region Define public functions.

function Test-Transcript {
	<#
		.SYNOPSIS
			Determines if transcription is in progress.

		.DESCRIPTION
			The Test-Transcript function determines if transcription is in progress. It returns TRUE ($true) if the host is transcribing output to a file and FALSE ($false) if the host is not transcribing output to a file.

		.EXAMPLE
			PS C:\> Test-Transcript

			Description
			-----------
			This command tests to see if transcription is in progress.

		.INPUTS
			None

		.OUTPUTS
			System.Boolean

		.NOTES
			The commands that contain the Transcript noun (the Transcript commands) enable transcription in a PowerShell host. They are designed to allow you to record all or a portion of your session. Use them to record local or remote PowerShell or legacy commands and their output.

		.LINK
			Start-Transcript

		.LINK
			Stop-Transcript
	#>
	[CmdletBinding()]
	param()
	try {
		[bool]$script:TranscriptConfiguration.Count
	}
	catch {
		throw
	}
}
Export-ModuleMember -Function Test-Transcript

New-Alias -Name ttrs -Value Test-Transcript
Export-ModuleMember -Alias ttrs

function Start-Transcript {
	<#
	.ForwardHelpTargetName Start-Transcript
	.ForwardHelpCategory Cmdlet
	#>
	[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
	param(
		[Parameter(Position=0)]
		[Alias('PSPath')]
		[ValidateNotNullOrEmpty()]
		[System.String]
		${Path},

		[Parameter()]
		[System.Management.Automation.SwitchParameter]
		${Append},

		[Parameter()]
		[System.Management.Automation.SwitchParameter]
		${Force},

		[Parameter()]
		[System.Management.Automation.SwitchParameter]
		${NoClobber}
	)
	try {	
		if ($globalTranscriptPath = Get-Variable -Scope Global -Name Transcript -ValueOnly -ErrorAction SilentlyContinue) {
			$transcriptionPath = $global:Transcript
		} else {
			$transcriptionPath = "{0}\PowerShell_transcript.{1}.txt" -f [System.Environment]::GetFolderPath('MyDocuments'),(Get-Date -Format yyyyMMddHHmmss)
		}
		if ($PSBoundParameters.ContainsKey('Path')) {
			$transcriptionPath = $Path
		}
		if ($PSBoundParameters.ContainsKey('WhatIf') -and $PSBoundParameters.WhatIf) {
			$innerMessage = (Get-ResourceString -BaseName CommandBaseStrings -ResourceId ShouldProcessMessage) -f 'Start-Transcript',$transcriptionPath
			$outerMessage = (Get-ResourceString -BaseName CommandBaseStrings -ResourceId ShouldProcessWhatIfMessage) -f $innerMessage
			Write-Host $outerMessage
			return
		}
		if ($PSBoundParameters.ContainsKey('Confirm') -and $PSBoundParameters.Confirm) {
			$label = Get-ResourceString -BaseName CommandBaseStrings -ResourceId InquireCaptionDefault
			$caption = Get-ResourceString -BaseName CommandBaseStrings -ResourceId ShouldProcessWarningCallback
			$action = (Get-ResourceString -BaseName CommandBaseStrings -ResourceId ShouldProcessMessage) -f 'Start-Transcript',$transcriptionPath
			$yes = Get-ResourceString -BaseName CommandBaseStrings -ResourceId ContinueOneLabel
			$yesToAll = Get-ResourceString -BaseName CommandBaseStrings -ResourceId ContinueAllLabel
			$no = Get-ResourceString -BaseName CommandBaseStrings -ResourceId SkipOneLabel
			$noToAll = Get-ResourceString -BaseName CommandBaseStrings -ResourceId SkipAllLabel
			$choices = [System.Management.Automation.Host.ChoiceDescription[]]@(
				New-Object -TypeName System.Management.Automation.Host.ChoiceDescription((Get-ResourceString -BaseName CommandBaseStrings -ResourceId ContinueOneLabel),(Get-ResourceString -BaseName CommandBaseStrings -ResourceId ContinueOneHelpMessage))
				New-Object -TypeName System.Management.Automation.Host.ChoiceDescription((Get-ResourceString -BaseName CommandBaseStrings -ResourceId ContinueAllLabel),(Get-ResourceString -BaseName CommandBaseStrings -ResourceId ContinueAllHelpMessage))
				New-Object -TypeName System.Management.Automation.Host.ChoiceDescription((Get-ResourceString -BaseName CommandBaseStrings -ResourceId SkipOneLabel),(Get-ResourceString -BaseName CommandBaseStrings -ResourceId SkipOneHelpMessage))
				New-Object -TypeName System.Management.Automation.Host.ChoiceDescription((Get-ResourceString -BaseName CommandBaseStrings -ResourceId SkipAllLabel),(Get-ResourceString -BaseName CommandBaseStrings -ResourceId SkipAllHelpMessage))
			)
			$result = $Host.UI.PromptForChoice($label,"${caption}$([System.Environment]::NewLine)${action}",$choices,0)
			if ($result -gt 1) {
				return
			}
		}
		if ($transcriptionPath -notmatch ':') {
			$transcriptionPath = Join-Path -Path $pwd.Path -ChildPath $transcriptionPath
		}
		if (Test-Transcript) {
			$message = Get-ResourceString -BaseName TranscriptStrings -ResourceId TranscriptionInProgress
			$exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $message
			throw $exception
		}
		if (-not (Test-Path -Path $transcriptionPath -IsValid)) {
			$message = Get-ResourceString -BaseName TranscriptStrings -ResourceId CannotStartTranscription
			$exception = New-Object -TypeName System.Management.Automation.PSInvalidOperationException -ArgumentList $message
			throw $exception
		}
		if (($pathQualifier = Split-Path -Path $transcriptionPath -Qualifier) -and
		    ($drive = Get-PSDrive -Name ($pathQualifier -replace ':$') -ErrorAction SilentlyContinue) -and
			($drive.Provider.Name -ne 'FileSystem')) {
			$message = Get-ResourceString -BaseName TranscriptStrings -ResourceId ReadWriteFileNotFileSystemProvider
			$exception = New-Object -TypeName System.Management.Automation.PSInvalidOperationException -ArgumentList ($message -f $drive.Provider.ToString())
			throw $exception
		}
		$file = Get-Item -Path $transcriptionPath -ErrorAction SilentlyContinue
		if ($file -is [System.Array]) {
			$message = Get-ResourceString -BaseName TranscriptStrings -ResourceId MultipleFilesNotSupported
			$exception = New-Object -TypeName System.Management.Automation.PSInvalidOperationException -ArgumentList $message
			throw $exception
		} elseif ($file) {
			if ($PSBoundParameters.ContainsKey('NoClobber') -and $PSBoundParameters.NoClobber) {
				$message = (Get-ResourceString -BaseName TranscriptStrings -ResourceId TranscriptFileExistsNoClobber) -f $transcriptionPath,'NoClobber'
				$exception = New-Object -TypeName System.UnauthorizedAccessException -ArgumentList $message
				throw $exception
			} elseif ($file.IsReadOnly -and ((-not $PSBoundParameters.ContainsKey('Force')) -or (-not $PSBoundParameters.Force))) {
				$message = (Get-ResourceString -BaseName TranscriptStrings -ResourceId TranscriptFileReadOnly) -f $transcriptionPath
				$exception = New-Object -TypeName System.Management.Automation.PSArgumentException -ArgumentList $message
				throw $exception
			}
		}
		if (($se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance) -and
		    ($embeddedConsoleWindow = $se.ToolWindows['PowerShellConsole']) -and
		    ($richTextBox = $embeddedConsoleWindow.Control.Controls.Find('RichTextBox1',$true) | Select-Object -First 1)) {
			$script:TranscriptConfiguration = $PSBoundParameters
			$script:TranscriptConfiguration.Remove('Path') | Out-Null
			$script:TranscriptConfiguration['FilePath'] = $transcriptionPath
			$headerParameters = @(
				Get-Date
				[System.Environment]::UserDomainName
				[System.Environment]::UserName
				[System.Environment]::MachineName
				[System.Environment]::OSVersion.VersionString
			)
			$HostTextWriter.WriteLine([string]((Get-ResourceString -BaseName ConsoleHostStrings -ResourceId TranscriptPrologue) -f $headerParameters), [string]$script:TranscriptConfiguration.FilePath)
			$script:TranscriptConfiguration['Append'] = $true
			$script:LastCaretPosition = $richTextBox.TextLength
			$HostTextWriter.StartTranscript([string]$script:TranscriptConfiguration.FilePath, [Windows.Forms.RichTextBox]$richTextBox)			
			$message = (Get-ResourceString -BaseName TranscriptStrings -ResourceId TranscriptionStarted) -f $script:TranscriptConfiguration.FilePath
			Write-Host $message
		} else {			
			$message = Get-ResourceString -BaseName TranscriptStrings -ResourceId HostDoesNotSupportTranscription
			$exception = New-Object -TypeName System.Management.Automation.PSNotSupportedException -ArgumentList $message
			throw $exception
		}
	}
	catch {
		$script:TranscriptConfiguration = @{}
		throw
	}
}
Export-ModuleMember -Function Start-Transcript

New-Alias -Name satrs -Value Start-Transcript
Export-ModuleMember -Alias satrs

function Stop-Transcript {
	<#
	.ForwardHelpTargetName Stop-Transcript
	.ForwardHelpCategory Cmdlet
	#>
	[CmdletBinding()]
	param()
	try {
		if (-not (Test-Transcript)) {
			$message = Get-ResourceString -BaseName TranscriptStrings -ResourceId TranscriptionNotInProgress
			$exception = New-Object -TypeName System.Management.Automation.PSInvalidOperationException -ArgumentList $message
			throw $exception
		}
		if (($se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance) -and
		    ($embeddedConsoleWindow = $se.ToolWindows['PowerShellConsole']) -and
		    ($richTextBox = $embeddedConsoleWindow.Control.Controls.Find('RichTextBox1',$true) | Select-Object -First 1)) {						
			$message = (Get-ResourceString -BaseName TranscriptStrings -ResourceId TranscriptionStopped) -f $script:TranscriptConfiguration.FilePath			
			Write-Host $message
			$HostTextWriter.StopTranscript()			
			$HostTextWriter.WriteLine([string]((Get-ResourceString -BaseName ConsoleHostStrings -ResourceId TranscriptEpilogue) -f (Get-Date)), [string]::Empty)
			$script:TranscriptConfiguration = @{}
		} else {
			$message = Get-ResourceString -BaseName TranscriptStrings -ResourceId HostDoesNotSupportTranscription
			$exception = New-Object -TypeName System.Management.Automation.PSNotSupportedException -ArgumentList $message
			throw $exception
		}
	}
	catch {
		$script:TranscriptConfiguration = @{}
		throw
	}
}
Export-ModuleMember -Function Stop-Transcript

New-Alias -Name sptrs -Value Stop-Transcript
Export-ModuleMember -Alias sptrs

#endregion

#region Clean-up the Add-on when it is removed.

$ExecutionContext.SessionState.Module.OnRemove = {
	$se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

	#region Stop transcribing if it is currently enabled.

	if (Test-Transcript) {
		Stop-Transcript
	}

	#endregion
}

#endregion

# SIG # Begin signature block
# MIId3wYJKoZIhvcNAQcCoIId0DCCHcwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfmv032Pcvtwf5+dTdAyP6Ko9
# IcigghjPMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggTTMIIDu6ADAgECAhAY2tGeJn3ou0ohWM3MaztKMA0GCSqGSIb3DQEBBQUAMIHK
# MQswCQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xHzAdBgNVBAsT
# FlZlcmlTaWduIFRydXN0IE5ldHdvcmsxOjA4BgNVBAsTMShjKSAyMDA2IFZlcmlT
# aWduLCBJbmMuIC0gRm9yIGF1dGhvcml6ZWQgdXNlIG9ubHkxRTBDBgNVBAMTPFZl
# cmlTaWduIENsYXNzIDMgUHVibGljIFByaW1hcnkgQ2VydGlmaWNhdGlvbiBBdXRo
# b3JpdHkgLSBHNTAeFw0wNjExMDgwMDAwMDBaFw0zNjA3MTYyMzU5NTlaMIHKMQsw
# CQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xHzAdBgNVBAsTFlZl
# cmlTaWduIFRydXN0IE5ldHdvcmsxOjA4BgNVBAsTMShjKSAyMDA2IFZlcmlTaWdu
# LCBJbmMuIC0gRm9yIGF1dGhvcml6ZWQgdXNlIG9ubHkxRTBDBgNVBAMTPFZlcmlT
# aWduIENsYXNzIDMgUHVibGljIFByaW1hcnkgQ2VydGlmaWNhdGlvbiBBdXRob3Jp
# dHkgLSBHNTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK8kCAgpejWe
# YAyq50s7Ttx8vDxFHLsr4P4pAvlXCKNkhRUn9fGtyDGJXSLoKqqmQrOP+LlVt7G3
# S7P+j34HV+zvQ9tmYhVhz2ANpNje+ODDYgg9VBPrScpZVIUm5SuPG5/r9aGRwjNJ
# 2ENjalJL0o/ocFFN0Ylpe8dw9rPcEnTbe11LVtOWvxV3obD0oiXyrxySZxjl9AYE
# 75C55ADk3Tq1Gf8CuvQ87uCL6zeL7PTXrPL28D2v3XWRMxkdHEDLdCQZIZPZFP6s
# KlLHj9UESeSNY0eIPGmDy/5HvSt+T8WVrg6d1NFDwGdz4xQIfuU/n3O4MwrPXT80
# h5aK7lPoJRUCAwEAAaOBsjCBrzAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQE
# AwIBBjBtBggrBgEFBQcBDARhMF+hXaBbMFkwVzBVFglpbWFnZS9naWYwITAfMAcG
# BSsOAwIaBBSP5dMahqyNjmvDz4Bq1EgYLHsZLjAlFiNodHRwOi8vbG9nby52ZXJp
# c2lnbi5jb20vdnNsb2dvLmdpZjAdBgNVHQ4EFgQUf9Nlp8Ld7LvwMAnzQzn6Aq8z
# MTMwDQYJKoZIhvcNAQEFBQADggEBAJMkSjBfYs/YGpgvPercmS29d/aleSI47MSn
# oHgSrWIORXBkxeeXZi2YCX5fr9bMKGXyAaoIGkfe+fl8kloIaSAN2T5tbjwNbtjm
# BpFAGLn4we3f20Gq4JYgyc1kFTiByZTuooQpCxNvjtsM3SUC26SLGUTSQXoFaUpY
# T2DKfoJqCwKqJRc5tdt/54RlKpWKvYbeXoEWgy0QzN79qIIqbSgfDQvE5ecaJhnh
# 9BFvELWV/OdCBTLbzp1RXii2noXTW++lfUVAco63DmsOBvszNUhxuJ0ni8RlXw2G
# dpxEevaVXPZdMggzpFS2GD9oXPJCSoU4VINf0egs8qwR1qjtY2owggVNMIIENaAD
# AgECAhAC5D+LDsdLzyijrO9Fle9rMA0GCSqGSIb3DQEBBQUAMIG0MQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xHzAdBgNVBAsTFlZlcmlTaWdu
# IFRydXN0IE5ldHdvcmsxOzA5BgNVBAsTMlRlcm1zIG9mIHVzZSBhdCBodHRwczov
# L3d3dy52ZXJpc2lnbi5jb20vcnBhIChjKTEwMS4wLAYDVQQDEyVWZXJpU2lnbiBD
# bGFzcyAzIENvZGUgU2lnbmluZyAyMDEwIENBMB4XDTEzMDQzMDAwMDAwMFoXDTE2
# MDQyOTIzNTk1OVowgZAxCzAJBgNVBAYTAlVTMQ4wDAYDVQQIEwVUZXhhczETMBEG
# A1UEBxMKUm91bmQgUm9jazENMAsGA1UEChQERGVsbDE+MDwGA1UECxM1RGlnaXRh
# bCBJRCBDbGFzcyAzIC0gTWljcm9zb2Z0IFNvZnR3YXJlIFZhbGlkYXRpb24gdjIx
# DTALBgNVBAMUBERlbGwwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDW
# Ieq0GYblhkMmx6Gq4kLDd2SSARqrs3yZgYLNAmvre9Q5WiLId5+voSFQfPehaAI4
# mqZiJp8XI6gP0L0Duhh3PpAptPA4KeZ715Ht2eloIESEnrZIcSQ3Q/dQDvcVIMuO
# 8JVAnNfyJ2B2wrJ1869thum7P8Zi8fmRnRBz9uVscusHiFuVaILUz1bU8uHb5y0E
# bcIfv8AcNYnkBo4R2uP4e5dzsiSKKJRjshv+EgISz0UEWipevIp3oUZtNtkUdyLd
# lZuzV0HlnMlV0XQwUIK7usRqn+Qk4iJlxQz7oTzZmNDYXcANyZ6TJgN+4Nog3tGo
# 0F75wktouny7cXuOe0U1AgMBAAGjggF7MIIBdzAJBgNVHRMEAjAAMA4GA1UdDwEB
# /wQEAwIHgDBABgNVHR8EOTA3MDWgM6Axhi9odHRwOi8vY3NjMy0yMDEwLWNybC52
# ZXJpc2lnbi5jb20vQ1NDMy0yMDEwLmNybDBEBgNVHSAEPTA7MDkGC2CGSAGG+EUB
# BxcDMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LnZlcmlzaWduLmNvbS9ycGEw
# EwYDVR0lBAwwCgYIKwYBBQUHAwMwcQYIKwYBBQUHAQEEZTBjMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC52ZXJpc2lnbi5jb20wOwYIKwYBBQUHMAKGL2h0dHA6Ly9j
# c2MzLTIwMTAtYWlhLnZlcmlzaWduLmNvbS9DU0MzLTIwMTAuY2VyMB8GA1UdIwQY
# MBaAFM+Zqep7JvRLyY6P1/AFJu/j0qedMBEGCWCGSAGG+EIBAQQEAwIEEDAWBgor
# BgEEAYI3AgEbBAgwBgEBAAEB/zANBgkqhkiG9w0BAQUFAAOCAQEAEJ0v1F+Zh4IF
# C9vIYhqVUIQHHyfGsSVAisS09ZyDFPGpL/tqn+afeNURZ6rePlWpZpnr+7ILgx6M
# sEREKEWowDe5O7I6OyD9OnDjYxZDYVEMTWCxRDp42+qvxtEtKpU2WKUaqsAgQjlp
# hoOr9PJsnn5VNyT78WriKoJlYp0g4diiHkFqk+PUngqZT3mcd/0e2VjNH0kwXgnd
# PXtYOMHq/X+UKdNd4XEwSrh/7bdTrczR8pwxs3xaBYH259832aiz7/KdHE4ZcW6w
# 9OX/ZFOavlO2Ij8TyhYaH6su8eA4YTMJlK3W4PEYxXPzJvKY8KYm3bJzu+4jQgHM
# E4FE6vYFcDCCBgowggTyoAMCAQICEFIA5aolVvwahu2WydRLM8cwDQYJKoZIhvcN
# AQEFBQAwgcoxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEf
# MB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE6MDgGA1UECxMxKGMpIDIw
# MDYgVmVyaVNpZ24sIEluYy4gLSBGb3IgYXV0aG9yaXplZCB1c2Ugb25seTFFMEMG
# A1UEAxM8VmVyaVNpZ24gQ2xhc3MgMyBQdWJsaWMgUHJpbWFyeSBDZXJ0aWZpY2F0
# aW9uIEF1dGhvcml0eSAtIEc1MB4XDTEwMDIwODAwMDAwMFoXDTIwMDIwNzIzNTk1
# OVowgbQxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEfMB0G
# A1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE7MDkGA1UECxMyVGVybXMgb2Yg
# dXNlIGF0IGh0dHBzOi8vd3d3LnZlcmlzaWduLmNvbS9ycGEgKGMpMTAxLjAsBgNV
# BAMTJVZlcmlTaWduIENsYXNzIDMgQ29kZSBTaWduaW5nIDIwMTAgQ0EwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD1I0tepdeKuzLp1Ff37+THJn6tGZj+
# qJ19lPY2axDXdYEwfwRof8srdR7NHQiM32mUpzejnHuA4Jnh7jdNX847FO6G1ND1
# JzW8JQs4p4xjnRejCKWrsPvNamKCTNUh2hvZ8eOEO4oqT4VbkAFPyad2EH8nA3y+
# rn59wd35BbwbSJxp58CkPDxBAD7fluXF5JRx1lUBxwAmSkA8taEmqQynbYCOkCV7
# z78/HOsvlvrlh3fGtVayejtUMFMb32I0/x7R9FqTKIXlTBdOflv9pJOZf9/N76R1
# 7+8V9kfn+Bly2C40Gqa0p0x+vbtPDD1X8TDWpjaO1oB21xkupc1+NC2JAgMBAAGj
# ggH+MIIB+jASBgNVHRMBAf8ECDAGAQH/AgEAMHAGA1UdIARpMGcwZQYLYIZIAYb4
# RQEHFwMwVjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL2Nw
# czAqBggrBgEFBQcCAjAeGhxodHRwczovL3d3dy52ZXJpc2lnbi5jb20vcnBhMA4G
# A1UdDwEB/wQEAwIBBjBtBggrBgEFBQcBDARhMF+hXaBbMFkwVzBVFglpbWFnZS9n
# aWYwITAfMAcGBSsOAwIaBBSP5dMahqyNjmvDz4Bq1EgYLHsZLjAlFiNodHRwOi8v
# bG9nby52ZXJpc2lnbi5jb20vdnNsb2dvLmdpZjA0BgNVHR8ELTArMCmgJ6AlhiNo
# dHRwOi8vY3JsLnZlcmlzaWduLmNvbS9wY2EzLWc1LmNybDA0BggrBgEFBQcBAQQo
# MCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLnZlcmlzaWduLmNvbTAdBgNVHSUE
# FjAUBggrBgEFBQcDAgYIKwYBBQUHAwMwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMT
# EFZlcmlTaWduTVBLSS0yLTgwHQYDVR0OBBYEFM+Zqep7JvRLyY6P1/AFJu/j0qed
# MB8GA1UdIwQYMBaAFH/TZafC3ey78DAJ80M5+gKvMzEzMA0GCSqGSIb3DQEBBQUA
# A4IBAQBWIuY0pMRhy0i5Aa1WqGQP2YyRxLvMDOWteqAif99HOEotbNF/cRp87HCp
# sfBP5A8MU/oVXv50mEkkhYEmHJEUR7BMY4y7oTTUxkXoDYUmcwPQqYxkbdxxkuZF
# BWAVWVE5/FgUa/7UpO15awgMQXLnNyIGCb4j6T9Emh7pYZ3MsZBc/D3SjaxCPWU2
# 1LQ9QCiPmxDPIybMSyDLkB9djEw0yjzY5TfWb6UgvTTrJtmuDefFmvehtCGRM2+G
# 6Fi7JXx0Dlj+dRtjP84xfJuPG5aexVN2hFucrZH6rO2Tul3IIVPCglNjrxINUIcR
# Gz1UUpaKLJw9khoImgUux5OlSJHTMYIEejCCBHYCAQEwgckwgbQxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEfMB0GA1UECxMWVmVyaVNpZ24g
# VHJ1c3QgTmV0d29yazE7MDkGA1UECxMyVGVybXMgb2YgdXNlIGF0IGh0dHBzOi8v
# d3d3LnZlcmlzaWduLmNvbS9ycGEgKGMpMTAxLjAsBgNVBAMTJVZlcmlTaWduIENs
# YXNzIDMgQ29kZSBTaWduaW5nIDIwMTAgQ0ECEALkP4sOx0vPKKOs70WV72swCQYF
# Kw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJ
# KoZIhvcNAQkEMRYEFN7tWR991mFqRewY159o5uLugN5wMA0GCSqGSIb3DQEBAQUA
# BIIBABBRrJdYhIdOGKfcVzNVWYPzVyoNrGoWxemoXWgFR1ckITZXbGPNuv6xhCWa
# lu0GJcH7FONRkjUW9oxcA8yS08J97Ad54VOkUhFvGTxsB8Bg8epYTXo618cuh1XU
# 05vvmhTa4giY/o9gnIhsSLpcQsGQYLl2d8kk0rpEPvwxvXx2tIdPpkN9KizrOs/v
# XHv51MCWdVax01kWilFtxUHXovShrqdZ2sTK+0OBW2Va2rmIHyiqwSKoOj+txGDc
# S9sqfiKi0xlUihZiF61pbTeL3yZ15B8i8rH7Z+qg4r7xMIjBuwmCjvjWl2eWRDyK
# OEh7xIekQ9uRQeEhohxa3C3fjemhggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQC
# AQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRp
# b24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0Eg
# LSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkD
# MQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTMwNzA0MTMyMDEzWjAjBgkq
# hkiG9w0BCQQxFgQUda1VN4vVzMSDp0j99+FjB7Md3WwwDQYJKoZIhvcNAQEBBQAE
# ggEAA2dSFZZF/iWobcQp7VvBzFn/Aj/9VTukfrQGm4Qcon/hDwF9i5/KCud3slhi
# tnapIFAy+jOADt8aKVJlWTQgf5fwhphKtgN0hhWJXhEEFFcEOArUbYps0SKOn2WF
# Ge10z80zW9xuKMFWWswRAOWnXkoF0uhaMXKVEtfGzBRAc7toAt7nJwQMMh0/kGyA
# fsQsBak3AmPs+gfse38AVrTnXhmycAA/bkjGfj1DQt+Ogq69aD3UepaLkGBLbZcx
# NcIiZLnXmWjTE7GUSw7d7NKLwcayh2N41yglgCm8OQFPfRzmjyjgi4z2iQ6E482T
# 7hYh/DkRQXAYr73bDRZ7Z9q+Pw==
# SIG # End signature block
