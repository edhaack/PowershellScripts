#######################################################################################################################
# File:             Add-on.CallStackWindow.psm1                                                                       #
# Author:           Kirk Munro                                                                                        #
# Publisher:        Quest Software, Inc.                                                                              #
# Copyright:        © 2011 Quest Software, Inc. All rights reserved.                                                  #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   3. Check the Add-on.CallStackWindow module.                                                       #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this:                 #
#                       Import-Module -Name Add-on.CallStackWindow                                                    #
#                   Please provide feedback on the PowerGUI Forums.                                                   #
#######################################################################################################################

Set-StrictMode -Version 2

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

#region Initialize the Script Editor Add-on.

$minimumSdkVersion = [System.Version]'1.0'

if ($Host.Name –ne 'PowerGUIScriptEditorHost') {
	return
}

if (-not (Get-Variable -Name PGVersionTable -ErrorAction SilentlyContinue)) {
	[System.Windows.Forms.MessageBox]::Show([PowerShellTypeExtensions.Win32Window]::CurrentWindow,"The ""$(Split-Path -Path $PSScriptRoot -Leaf)"" Add-on module requires PowerGUI 3.0 or later. The current PowerGUI version is $($Host.Version).$([System.Environment]::NewLine * 2)Please upgrade to the latest version of PowerGUI and try again.",'PowerGUI 3.0 or later is required',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
	return
} elseif ($PGVersionTable.SDKVersion -lt $minimumSdkVersion) {
	[System.Windows.Forms.MessageBox]::Show([PowerShellTypeExtensions.Win32Window]::CurrentWindow,"The ""$(Split-Path -Path $PSScriptRoot -Leaf)"" Add-on module requires version $minimumSdkVersion or later of the PowerGUI Script Editor SDK. The current SDK version is $($PGVersionTable.SDKVersion).$([System.Environment]::NewLine * 2)Please upgrade to the latest version of PowerGUI and try again.","Version $minimumSdkVersion or later of the SDK is required",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
	return
}

#endregion

#region Load resources from disk.

$iconLibrary = @{
	# TODO: Load icons into this table.
	#       eg. DebugWindowsIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\DebugWindows.ico",16,16
	#           DebugWindowsIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\DebugWindows.ico",32,32
}

$imageLibrary = @{
	# TODO: Load images into this table.
	#       eg. DebugWindowsImage16 = $iconLibrary['DebugWindowsIcon16'].ToBitmap()
	#           DebugWindowsImage32 = $iconLibrary['DebugWindowsIcon32'].ToBitmap()
}

#endregion

#region Define helper variables.

[bool]$loadingModule = $true

#endregion

#region Define the event handlers.

$eventHandler = @{
	'OnStepInvoking' = [System.EventHandler[Quest.PowerGUI.SDK.CommandEventArgs]]{
		param(
			$sender,
			$eventArgs
		)
		& {
			$eventArgs.Canceled = $false
			if (($documentWindow = $PGSE.CurrentDocumentWindow) -and
			    ($documentWindow | Get-Member -Name Document -ErrorAction SilentlyContinue) -and
			    ($originalWindowProperty = $documentWindow.GetType().GetProperty('OriginalWindow',[System.Reflection.BindingFlags]'NonPublic,Instance')) -and
			    ($originalWindow = $originalWindowProperty.GetValue($documentWindow,$null)) -and
			    ($debuggingMethod = $PGSE.GetType().GetMethod('Debugging',[System.Reflection.BindingFlags]'NonPublic,Instance')) -and
			    (-not $debuggingMethod.Invoke($PGSE,$originalWindow)) -and
				($runToCursorCommand = $PGSE.Commands['DebugCommand.RunToCursor'])) {
				$eventArgs.Canceled = $true
				$documentWindow.Document.CaretLine = 1
				$documentWindow.Document.CaretCharacter = 1
				$runToCursorCommand.Invoke()
			}
		}
	}
	'DebuggerStateChanged' = [System.EventHandler]{
		$WhatIfPreference = $false
		$ConfirmPreference = [System.Management.Automation.ConfirmImpact]::None
		if ((-not $loadingModule) -and ($window = $PGSE.ToolWindows['Add-on.CallStackWindow'])) {
			if ($PGSE.DebuggerState -eq 'Paused') {
				#region Create a Go menu command to activate the CallStack window.

				if (-not ($goToCallStackCommand = $PGSE.Commands['GoCommand.CallStack'])) {
					$goToCallStackCommand = New-Object -TypeName Quest.PowerGUI.SDK.ItemCommand -ArgumentList 'GoCommand', 'CallStack'
					$goToCallStackCommand.Text = '&Call Stack'
					$goToCallStackCommand.Image = $imageLibrary['CallStackImage16']
					if ($goMenu = $PGSE.Menus['MenuBar.Go']) {
						$index = $goMenu.Items.Count + 1
						if ($index -lt 10) {
							$goToCallStackCommand.AddShortcut("Ctrl+${index}")
						}
					}
					$goToCallStackCommand.ScriptBlock = {
						if ($callStackWindow = $PGSE.ToolWindows['Add-on.CallStackWindow']) {
							$callStackWindow.Visible = $true
							$callStackWindow.Control.Invoke([EventHandler]{$callStackWindow.Control.Parent.Activate($true)})
						}
					}

					$PGSE.Commands.Add($goToCallStackCommand)
				}

				#endregion

				#region Add the Go to CallStack command to the Go menu.

				if ($goMenu = $PGSE.Menus['MenuBar.Go']) {
					$goMenu.Items.Add($goToCallStackCommand)
				}

				#endregion

				#region Load the current call stack and add it to the call stack window.

				$window.Visible = $true
				$window.Control.Items.Clear() | Out-Null
				$callStack = Get-PSCallStack | Select-Object -Skip 1
				for ($index = 0; $index -lt ($callStack.Count - 1); $index++) {
					if ($callStack[$index].InvocationInfo.ScriptName) {
						$location = Split-Path -Path $callStack[$index].InvocationInfo.ScriptName -Leaf
						$item = $window.Control.Items.Add($location)
						$item.ToolTipText = $callStack[$index].InvocationInfo.ScriptName
						$position = "Ln $($callStack[$index].InvocationInfo.ScriptLineNumber) | Ch $($callStack[$index].InvocationInfo.OffsetInLine)"
						$item.Subitems.Add($position) | Out-Null
						$item.Subitems.Add($callStack[$index].InvocationInfo.ScriptLineNumber) | Out-Null
						$item.Subitems.Add($callStack[$index].InvocationInfo.OffsetInLine) | Out-Null
						$item.Subitems.Add($callStack[$index].InvocationInfo.ScriptName) | Out-Null
					} else {
						$item = $window.Control.Items.Add('prompt')
						$item.Subitems.Add('N/A') | Out-Null
						$item.Subitems.Add('N/A') | Out-Null
						$item.Subitems.Add('N/A') | Out-Null
						$item.Subitems.Add('N/A') | Out-Null
					}
					if ($callStack[$index].InvocationInfo.OffsetInLine -gt $callStack[$index].InvocationInfo.Line.Length) {
						$command = $callStack[$index].InvocationInfo.Line + ' <<<<'
					} else {
						$command = $callStack[$index].InvocationInfo.Line.Insert($callStack[$index].InvocationInfo.OffsetInLine - 1,' <<<<')
					}
					$item.Subitems.Add($command) | Out-Null
					if ($callStack[$index].Arguments -ne '{}') {
						$arguments = $callStack[$index].Arguments -replace '^{(.+)}$','$1'
						$item.Subitems.Add($arguments) | Out-Null
					} else {
						$item.Subitems.Add('None') | Out-Null
					}
				}

				#endregion
			} elseif ($PGSE.DebuggerState -eq 'Stopped') {
				#region Remove the CallStack menu item from the Go menu.

				if (($goMenu = $PGSE.Menus['MenuBar.Go']) -and
				    ($goToCallStackMenuItem = $goMenu.Items['GoCommand.CallStack'])) {
					$goMenu.Items.Remove($goToCallStackMenuItem) | Out-Null
				}

				#endregion

				#region Remove the Go to CallStack command.

				if ($goToCallStackCommand = $PGSE.Commands['GoCommand.CallStack']) {
					$PGSE.Commands.Remove($goToCallStackCommand) | Out-Null
				}

				#endregion

				#region Clear and hide the call stack window.

				$window.Visible = $false
				$window.Control.Items.Clear() | Out-Null

				#endregion
			}
		}
	}
	'OnListViewItemDoubleClick' = [System.EventHandler]{
		if ($callStackWindow = $PGSE.ToolWindows['Add-on.CallStackWindow']) {
			$callStackListView = $callStackWindow.Control
			if (($callStackListView.SelectedItems.Count -eq 1) -and
			    ($callStackListView.SelectedItems[0].SubItems[4].Text -ne 'N/A')) {
				$filePath = $callStackListView.SelectedItems[0].SubItems[4].Text
				$lineNumber = $callStackListView.SelectedItems[0].SubItems[2].Text
				$characterNumber = $callStackListView.SelectedItems[0].SubItems[3].Text
				$fileOpen = $false
				foreach ($documentWindow in $PGSE.DocumentWindows) {
					if (-not ($documentWindow | Get-Member -Name Document -ErrorAction SilentlyContinue)) {
						continue
					}
					$actualFileName = $documentWindow.Document.Path
					if ((-not $documentWindow.Document.IsSaved) -and
					    ($originalWindowProperty = $documentWindow.GetType().GetProperty('OriginalWindow',[System.Reflection.BindingFlags]'NonPublic,Instance')) -and
					    ($originalWindow = $originalWindowProperty.GetValue($documentWindow,$null)) -and
					    ($scriptEditorControl = $originalWindow.PSControl)) {
						$actualFileName = $scriptEditorControl.ActualFileName
					}
					if ($actualFileName -eq $filePath) {
						$fileOpen = $true
						$documentWindow.Activate()
						$documentWindow.Document.EnsureVisible($lineNumber)
						$documentWindow.Document.SetCaretPosition($lineNumber,$characterNumber)
						break
					}
				}
				if (-not $fileOpen) {
					$documentWindow = $PGSE.DocumentWindows.Add($filePath)
					$documentWindow.Activate()
					$documentWindow.Document.EnsureVisible($lineNumber)
					$documentWindow.Document.SetCaretPosition($lineNumber,$characterNumber)
				}
			} elseif (($callStackListView.SelectedItems[0].Text -eq 'prompt') -and
			          ($goToPowerShellConsoleCommand = $PGSE.Commands['GoCommand.Output'])) {
				$goToPowerShellConsoleCommand.Invoke()
			}
		}
	}
}

#endregion

#region Create the control that will appear in the dockable window.

$callStackListView = New-Object -TypeName System.Windows.Forms.ListView
$callStackListView.View = 'Details'
$callStackListView.FullRowSelect = $true
$callStackListView.ShowItemToolTips = $true
$columnHeader = $callStackListView.Columns.Add('Location')
$columnHeader.Width = 150
$columnHeader = $callStackListView.Columns.Add('Position')
$columnHeader.Width = 100
$columnHeader = $callStackListView.Columns.Add('Line')
$columnHeader.Width = 0
$columnHeader = $callStackListView.Columns.Add('Character')
$columnHeader.Width = 0
$columnHeader = $callStackListView.Columns.Add('Path')
$columnHeader.Width = 0
$columnHeader = $callStackListView.Columns.Add('Command')
$columnHeader.Width = 600
$columnHeader = $callStackListView.Columns.Add('Arguments')
$columnHeader.Width = 150
$callStackListView.add_DoubleClick($eventHandler['OnListViewItemDoubleClick'])

#endregion

#region Create and/or initialize the CallStack dockable window.

if (-not ($callStackWindow = $PGSE.ToolWindows['Add-on.CallStackWindow'])) {
	$callStackWindow = $PGSE.ToolWindows.Add('Add-on.CallStackWindow')
	$callStackWindow.Title = 'Call &Stack' -replace '&'
	$callStackWindow.Control = $callStackListView
	if (($VariablesWindow = $PGSE.ToolWindows['Variables']) -and $VariablesWindow.Control -and $VariablesWindow.Visible) {
		$callStackWindow.Control.Parent.Invoke([EventHandler]{$callStackWindow.Control.Parent.DockTo($VariablesWindow.Control.Parent,'Attach')})
	} elseif (($PowerShellConsoleWindow = $PGSE.ToolWindows['PowerShellConsole']) -and $PowerShellConsoleWindow.Control -and $PowerShellConsoleWindow.Visible) {
		$callStackWindow.Control.Parent.Invoke([EventHandler]{$callStackWindow.Control.Parent.DockTo($PowerShellConsoleWindow.Control.Parent,'Attach')})
	} else {
		$callStackWindow.Control.Parent.Invoke([EventHandler]{$callStackWindow.Control.Parent.DockTo($PowerShellConsoleWindow.Control.Parent.DockManager.DockManager,'BottomInner')})
	}
	$callStackWindow.Visible = $false
} else {
	$callStackWindow.Control = $callStackListView
}

#endregion

#region Activate the StepInto OnInvoking event handler.

if ($stepIntoCommand = $PGSE.Commands['DebugCommand.StepInto']) {
	$stepIntoCommand.add_Invoking($eventHandler['OnStepInvoking'])
}

#endregion

#region Activate the StepOver OnInvoking event handler.

if ($stepOverCommand = $PGSE.Commands['DebugCommand.StepOver']) {
	$stepOverCommand.add_Invoking($eventHandler['OnStepInvoking'])
}

#endregion

#region Activate the Debugger State Changed event handler.

$PGSE.add_DebuggerStateChanged($eventHandler.DebuggerStateChanged)

#endregion

#region Clean-up the Add-on when it is removed.

$ExecutionContext.SessionState.Module.OnRemove = {
	#region Deactivate the Debugger State Changed event handler.

	$PGSE.remove_DebuggerStateChanged($eventHandler.DebuggerStateChanged)

	#endregion

	#region Deactivate the StepOver OnInvoking event handler.

	if ($stepOverCommand = $PGSE.Commands['DebugCommand.StepOver']) {
		$stepOverCommand.remove_Invoking($eventHandler['OnStepInvoking'])
	}

	#endregion

	#region Deactivate the StepInto OnInvoking event handler.

	if ($stepIntoCommand = $PGSE.Commands['DebugCommand.StepInto']) {
		$stepIntoCommand.remove_Invoking($eventHandler['OnStepInvoking'])
	}

	#endregion

	#region Remove the CallStack window.

	if ($callStackWindow = $PGSE.ToolWindows['Add-on.CallStackWindow']) {
		$PGSE.ToolWindows.Remove($callStackWindow) | Out-Null
	}

	#endregion
}

#endregion

#region Clear the loading module flag.

$loadingModule = $false

#endregion


# SIG # Begin signature block
# MIId3wYJKoZIhvcNAQcCoIId0DCCHcwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUb+XrpQWteAvICnQIG7tLu/QI
# RaagghjPMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# KoZIhvcNAQkEMRYEFHfxfjsrxOfRCimixH3ntRvwvd2CMA0GCSqGSIb3DQEBAQUA
# BIIBALzX938+zsVVszM9XogTivRmtdF2/AK0xDshpS9HW2biDk6BbUH7TQ1ThZdT
# Qf8ap+Qv0CoAFuICdtOl1iS5sXry6B8BcDLava+flSeRsa39XqKFdE5HrlhO0Xxc
# pBqMggVYMWRm0vxnJbFhhEIEEHvoBGvNMwDNGAXiRmnEVfRLaQuFWDW5KeqclS6I
# eOG5fRvnJ7KbQbR7eUIMGNgeAp2S3858ji+JjcOY/W/tNFTKxFFKnSquCj0wGTFC
# Mf05QadJIMA3Htvn4Isph5jeSDf0ANBYt7A8hyVFQ5XhNU0ywNiO8XwNE6XbEXPZ
# aSo8lQrADzD6ndO+x6vpR+FVcpuhggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQC
# AQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRp
# b24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0Eg
# LSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkD
# MQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTMwNjIxMTIwMzE2WjAjBgkq
# hkiG9w0BCQQxFgQUPy3xdYVs+/yHYEGedjnqFDjEkB0wDQYJKoZIhvcNAQEBBQAE
# ggEAZWS0cr3HgH+8Sb5B1qd3BRRJvlyxmBRmwhuwiX2YSw2FgMbCQ/LmBUx77YbH
# Rv7pnZHcy7c9dk1GDm+uNa+S+frhoEHwv3zu0DsK40G49YtS0n0adaLAq/ugxpao
# gQioLKbTGyoMEuIRVtQ2UXvHM+RVbCUIxY6V0GioaC1W8L/m7wRrAurkpenzMnAC
# 3wgkCcd72bURvfg7kSSbczx8QaNGKvUt/SISykScPnEQWSqva5jyPzc6oelWp4WR
# Is0HZ9Eh7MWJCNX4rfqN75eHZLXADmS0DaFWKcHf1TUzm+whpp4t3NH12zJwOorY
# ralvyYtJl+1CbNRemXxWfxyhNg==
# SIG # End signature block
