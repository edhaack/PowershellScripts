#######################################################################################################################
# File:             Add-on.CallStackWindow.psm1                                                                       #
# Author:           Sergey Terentyev                                                                                  #
# Publisher:        Quest Software, Inc.                                                                              #
# Copyright:        © 2013 Quest Software, Inc. All rights reserved.                                                  #
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

#region Define the .Net Extensions

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

if (-not ('PowerShellTypeExtensions.CallStackPlugin' -as [System.Type])) {
	$cSharpCode = @'
using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Windows.Forms;
using Quest.PowerGUI.SDK;


namespace PowerShellTypeExtensions
{
    public class CallStackPlugin
    {
        private const string CallStackWindowName = "Add-on.CallStackWindow";
        private const string VariablesWindowName = "Variables";
        private const string PowerShellWindowName = "PowerShellConsole";
        private const string NAValue = "N/A";
        private const string NoneValue = "None";

        private readonly ScriptEditor _editor;
        private readonly ToolWindow _callStackWindow;

        public CallStackPlugin(ScriptEditor editor, ListView listView)
        {
            _editor = editor;
            _callStackWindow = editor.ToolWindows[CallStackWindowName] ?? editor.ToolWindows.Add(CallStackWindowName);
			_callStackWindow.Title = "Call stack";
            _callStackWindow.Control = listView;
            _callStackWindow.Visible = false;

            object destControl;
            var destPropertyName = ActiproSoftware.UIStudio.Dock.DockOperationType.Attach;
            var variablesWindow = _editor.ToolWindows[VariablesWindowName];
            var powerShellConsoleWindow = _editor.ToolWindows[PowerShellWindowName];
            if (variablesWindow != null && variablesWindow.Control != null && variablesWindow.Visible)
            {
                destControl = variablesWindow.Control.Parent;
            }
            else if (powerShellConsoleWindow != null && powerShellConsoleWindow.Control != null && powerShellConsoleWindow.Visible)
            {
                destControl = powerShellConsoleWindow.Control.Parent;
            }
            else
            {
                destPropertyName = ActiproSoftware.UIStudio.Dock.DockOperationType.BottomInner;
                var main = _editor.GetType().GetField("_seMain", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(_editor);
                destControl = main.GetType().GetField("dockManager1", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(main);
            }

            _editor.Invoke((Action)(() => _callStackWindow.Control.Parent.GetType().GetMethod("DockTo", BindingFlags.InvokeMethod | BindingFlags.Instance | BindingFlags.Public).Invoke(_callStackWindow.Control.Parent, new[] { destControl, destPropertyName })));
            _editor.DebugContext.DebuggerStateChanged += OnDebugStateChanged;
            CallStackListView.MouseDoubleClick += OnDblClick;
        }

        public ToolWindow CallStackWindow
        {
            get { return _callStackWindow; }
        }

        public ListView CallStackListView
        {
            get { return CallStackWindow.Control as ListView; }
        }

        public void Remove()
        {
            _editor.DebugContext.DebuggerStateChanged -= OnDebugStateChanged;
            _editor.ToolWindows.Remove(_callStackWindow);
        }

        private void NamvigateToPrompt()
        {
            var goToPowerShellConsoleCommand = _editor.Commands["GoCommand.Output"] as ItemCommand;
            if (goToPowerShellConsoleCommand != null)
            {
                goToPowerShellConsoleCommand.Invoke();
            }
        }

        private DocumentWindow GetDocument(string filePath)
        {
            if (string.IsNullOrEmpty(filePath))
            {
                return _editor.CurrentDocumentWindow;
            }
            foreach (var documentWindow in _editor.DocumentWindows)
            {
                if (documentWindow.Document == null)
                {
                    continue;
                }

                if (StringComparer.InvariantCultureIgnoreCase.Equals(documentWindow.Document.Path, filePath))
                {
                    return documentWindow;
                }
            }

            return _editor.DocumentWindows.Add(filePath);
        }

        private void OnDblClick(object sender, EventArgs args)
        {
            if (CallStackListView.SelectedItems.Count != 1)
            {
                return;
            }
            if (!StringComparer.InvariantCultureIgnoreCase.Equals(CallStackListView.SelectedItems[0].SubItems[4].Text, NAValue))
            {
                var filePath = CallStackListView.SelectedItems[0].SubItems[4].Text;
                var lineNumber = int.Parse(CallStackListView.SelectedItems[0].SubItems[2].Text);
				var columnNumber = int.Parse(CallStackListView.SelectedItems[0].SubItems[3].Text);
                var documentWindow = GetDocument(filePath);

                documentWindow.Activate();
                documentWindow.Document.EnsureVisible(lineNumber);
                documentWindow.Document.SetCaretPosition(lineNumber, columnNumber);
            }
            else if (StringComparer.InvariantCultureIgnoreCase.Equals(CallStackListView.SelectedItems[0].Text, "prompt"))
            {
                NamvigateToPrompt();
            }
        }

        private void InsertItemToListView(string location, string tooltipText, string postion,
                                          string command, string args, string scriptName, 
										  string line, string column)
        {            
            tooltipText = tooltipText ?? string.Empty;
			location = string.IsNullOrEmpty(scriptName)? "prompt" : scriptName;
            postion = string.IsNullOrEmpty(scriptName)? NAValue : postion;
            command = command ?? string.Empty;
            args = string.IsNullOrEmpty(args) ? NoneValue : args;
            scriptName = string.IsNullOrEmpty(scriptName)? NAValue : scriptName;
            line = string.IsNullOrEmpty(scriptName)? NAValue : line;
			column = string.IsNullOrEmpty(scriptName)? NAValue : column;            

            var it = CallStackListView.Items.Add(location);
            it.ToolTipText = tooltipText;
            it.SubItems.Add(postion);
            it.SubItems.Add(line);
			it.SubItems.Add(column);
            it.SubItems.Add(scriptName);
            it.SubItems.Add(command);
            it.SubItems.Add(args);
        }

        private void OnDebugStateChanged(object sender, EventArgs args)
        {
            _editor.Invoke((Function)(() =>
            {                
				if (_editor.DebugContext.DebuggerState == DebuggerState.Stopped)
				{
					// Need to set once. Fixed lost focus issue in W8
					CallStackWindow.Visible = false;
				}
                else 
                {
					// Need to set once. Fixed lost focus issue in W8
					if (!CallStackWindow.Visible)
					{
						CallStackWindow.Visible = true;
					}
                    CallStackListView.Items.Clear();

                    foreach (var callStackItem in _editor.DebugContext.CallStack)
                    {
                        var arguments = !callStackItem.Arguments.Any()
                                            ? string.Empty
                                            : callStackItem.Arguments.Select(p => string.Format("{0}={1}", p.Key, p.Value))
                                                            .Aggregate((tmp, next) => string.Format("{0}, {1}", tmp, next));
                        var line = callStackItem.Line;
                        var column = callStackItem.Column;

                        InsertItemToListView(Path.GetFileName(callStackItem.ScriptName),
                                             callStackItem.ScriptName,
                                             string.Format("Ln {0} | Ch {1}", line, column),
                                             callStackItem.InvocationName,
                                             arguments,
                                             callStackItem.ScriptName,
                                             line.ToString(),
											 column.ToString());

                    }                    
                }
                return args;
            }));
        }
    }
}
'@	
$refs = @(	"System.Windows.Forms",
			"System.Core",
			"$PGHome\SDK.dll", 
			"$PGHome\ScriptEditor.Shared.dll",			
			"$PGHome\ActiproSoftware.UIStudio.Dock.Net20.dll",
			"$PGHome\ActiproSoftware.WinUICore.Net20.dll",
			"$PGHome\ActiproSoftware.Shared.Net20.dll",
			"$PGHome\ActiproSoftware.SyntaxEditor.Net20.dll")			

Add-Type -ReferencedAssemblies $refs -IgnoreWarnings -TypeDefinition $cSharpCode | Out-Null	
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
$columnHeader = $callStackListView.Columns.Add('Column')
$columnHeader.Width = 0
$columnHeader = $callStackListView.Columns.Add('Path')
$columnHeader.Width = 0
$columnHeader = $callStackListView.Columns.Add('Command')
$columnHeader.Width = 600
$columnHeader = $callStackListView.Columns.Add('Arguments')
$columnHeader.Width = 150

#endregion


#region Activate the Debugger State Changed event handler.

$CallStackPlugin = New-Object -TypeName  PowerShellTypeExtensions.CallStackPlugin -ArgumentList ($PGSE, [System.Windows.Forms.ListView]$callStackListView)

#endregion

#region Clean-up the Add-on when it is removed.

$ExecutionContext.SessionState.Module.OnRemove = { $CallStackPlugin.Remove() }
#endregion

#endregion

#region Clear the loading module flag.

$loadingModule = $false

#endregion


# SIG # Begin signature block
# MIIZCAYJKoZIhvcNAQcCoIIY+TCCGPUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvwqmlsq5mJGPfT+A5ls13p5O
# HqygghP4MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# ggVNMIIENaADAgECAhAC5D+LDsdLzyijrO9Fle9rMA0GCSqGSIb3DQEBBQUAMIG0
# MQswCQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xHzAdBgNVBAsT
# FlZlcmlTaWduIFRydXN0IE5ldHdvcmsxOzA5BgNVBAsTMlRlcm1zIG9mIHVzZSBh
# dCBodHRwczovL3d3dy52ZXJpc2lnbi5jb20vcnBhIChjKTEwMS4wLAYDVQQDEyVW
# ZXJpU2lnbiBDbGFzcyAzIENvZGUgU2lnbmluZyAyMDEwIENBMB4XDTEzMDQzMDAw
# MDAwMFoXDTE2MDQyOTIzNTk1OVowgZAxCzAJBgNVBAYTAlVTMQ4wDAYDVQQIEwVU
# ZXhhczETMBEGA1UEBxMKUm91bmQgUm9jazENMAsGA1UEChQERGVsbDE+MDwGA1UE
# CxM1RGlnaXRhbCBJRCBDbGFzcyAzIC0gTWljcm9zb2Z0IFNvZnR3YXJlIFZhbGlk
# YXRpb24gdjIxDTALBgNVBAMUBERlbGwwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
# ggEKAoIBAQDWIeq0GYblhkMmx6Gq4kLDd2SSARqrs3yZgYLNAmvre9Q5WiLId5+v
# oSFQfPehaAI4mqZiJp8XI6gP0L0Duhh3PpAptPA4KeZ715Ht2eloIESEnrZIcSQ3
# Q/dQDvcVIMuO8JVAnNfyJ2B2wrJ1869thum7P8Zi8fmRnRBz9uVscusHiFuVaILU
# z1bU8uHb5y0EbcIfv8AcNYnkBo4R2uP4e5dzsiSKKJRjshv+EgISz0UEWipevIp3
# oUZtNtkUdyLdlZuzV0HlnMlV0XQwUIK7usRqn+Qk4iJlxQz7oTzZmNDYXcANyZ6T
# JgN+4Nog3tGo0F75wktouny7cXuOe0U1AgMBAAGjggF7MIIBdzAJBgNVHRMEAjAA
# MA4GA1UdDwEB/wQEAwIHgDBABgNVHR8EOTA3MDWgM6Axhi9odHRwOi8vY3NjMy0y
# MDEwLWNybC52ZXJpc2lnbi5jb20vQ1NDMy0yMDEwLmNybDBEBgNVHSAEPTA7MDkG
# C2CGSAGG+EUBBxcDMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LnZlcmlzaWdu
# LmNvbS9ycGEwEwYDVR0lBAwwCgYIKwYBBQUHAwMwcQYIKwYBBQUHAQEEZTBjMCQG
# CCsGAQUFBzABhhhodHRwOi8vb2NzcC52ZXJpc2lnbi5jb20wOwYIKwYBBQUHMAKG
# L2h0dHA6Ly9jc2MzLTIwMTAtYWlhLnZlcmlzaWduLmNvbS9DU0MzLTIwMTAuY2Vy
# MB8GA1UdIwQYMBaAFM+Zqep7JvRLyY6P1/AFJu/j0qedMBEGCWCGSAGG+EIBAQQE
# AwIEEDAWBgorBgEEAYI3AgEbBAgwBgEBAAEB/zANBgkqhkiG9w0BAQUFAAOCAQEA
# EJ0v1F+Zh4IFC9vIYhqVUIQHHyfGsSVAisS09ZyDFPGpL/tqn+afeNURZ6rePlWp
# Zpnr+7ILgx6MsEREKEWowDe5O7I6OyD9OnDjYxZDYVEMTWCxRDp42+qvxtEtKpU2
# WKUaqsAgQjlphoOr9PJsnn5VNyT78WriKoJlYp0g4diiHkFqk+PUngqZT3mcd/0e
# 2VjNH0kwXgndPXtYOMHq/X+UKdNd4XEwSrh/7bdTrczR8pwxs3xaBYH259832aiz
# 7/KdHE4ZcW6w9OX/ZFOavlO2Ij8TyhYaH6su8eA4YTMJlK3W4PEYxXPzJvKY8KYm
# 3bJzu+4jQgHME4FE6vYFcDCCBgowggTyoAMCAQICEFIA5aolVvwahu2WydRLM8cw
# DQYJKoZIhvcNAQEFBQAwgcoxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2ln
# biwgSW5jLjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE6MDgGA1UE
# CxMxKGMpIDIwMDYgVmVyaVNpZ24sIEluYy4gLSBGb3IgYXV0aG9yaXplZCB1c2Ug
# b25seTFFMEMGA1UEAxM8VmVyaVNpZ24gQ2xhc3MgMyBQdWJsaWMgUHJpbWFyeSBD
# ZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSAtIEc1MB4XDTEwMDIwODAwMDAwMFoXDTIw
# MDIwNzIzNTk1OVowgbQxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwg
# SW5jLjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE7MDkGA1UECxMy
# VGVybXMgb2YgdXNlIGF0IGh0dHBzOi8vd3d3LnZlcmlzaWduLmNvbS9ycGEgKGMp
# MTAxLjAsBgNVBAMTJVZlcmlTaWduIENsYXNzIDMgQ29kZSBTaWduaW5nIDIwMTAg
# Q0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD1I0tepdeKuzLp1Ff3
# 7+THJn6tGZj+qJ19lPY2axDXdYEwfwRof8srdR7NHQiM32mUpzejnHuA4Jnh7jdN
# X847FO6G1ND1JzW8JQs4p4xjnRejCKWrsPvNamKCTNUh2hvZ8eOEO4oqT4VbkAFP
# yad2EH8nA3y+rn59wd35BbwbSJxp58CkPDxBAD7fluXF5JRx1lUBxwAmSkA8taEm
# qQynbYCOkCV7z78/HOsvlvrlh3fGtVayejtUMFMb32I0/x7R9FqTKIXlTBdOflv9
# pJOZf9/N76R17+8V9kfn+Bly2C40Gqa0p0x+vbtPDD1X8TDWpjaO1oB21xkupc1+
# NC2JAgMBAAGjggH+MIIB+jASBgNVHRMBAf8ECDAGAQH/AgEAMHAGA1UdIARpMGcw
# ZQYLYIZIAYb4RQEHFwMwVjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cudmVyaXNp
# Z24uY29tL2NwczAqBggrBgEFBQcCAjAeGhxodHRwczovL3d3dy52ZXJpc2lnbi5j
# b20vcnBhMA4GA1UdDwEB/wQEAwIBBjBtBggrBgEFBQcBDARhMF+hXaBbMFkwVzBV
# FglpbWFnZS9naWYwITAfMAcGBSsOAwIaBBSP5dMahqyNjmvDz4Bq1EgYLHsZLjAl
# FiNodHRwOi8vbG9nby52ZXJpc2lnbi5jb20vdnNsb2dvLmdpZjA0BgNVHR8ELTAr
# MCmgJ6AlhiNodHRwOi8vY3JsLnZlcmlzaWduLmNvbS9wY2EzLWc1LmNybDA0Bggr
# BgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLnZlcmlzaWduLmNv
# bTAdBgNVHSUEFjAUBggrBgEFBQcDAgYIKwYBBQUHAwMwKAYDVR0RBCEwH6QdMBsx
# GTAXBgNVBAMTEFZlcmlTaWduTVBLSS0yLTgwHQYDVR0OBBYEFM+Zqep7JvRLyY6P
# 1/AFJu/j0qedMB8GA1UdIwQYMBaAFH/TZafC3ey78DAJ80M5+gKvMzEzMA0GCSqG
# SIb3DQEBBQUAA4IBAQBWIuY0pMRhy0i5Aa1WqGQP2YyRxLvMDOWteqAif99HOEot
# bNF/cRp87HCpsfBP5A8MU/oVXv50mEkkhYEmHJEUR7BMY4y7oTTUxkXoDYUmcwPQ
# qYxkbdxxkuZFBWAVWVE5/FgUa/7UpO15awgMQXLnNyIGCb4j6T9Emh7pYZ3MsZBc
# /D3SjaxCPWU21LQ9QCiPmxDPIybMSyDLkB9djEw0yjzY5TfWb6UgvTTrJtmuDefF
# mvehtCGRM2+G6Fi7JXx0Dlj+dRtjP84xfJuPG5aexVN2hFucrZH6rO2Tul3IIVPC
# glNjrxINUIcRGz1UUpaKLJw9khoImgUux5OlSJHTMYIEejCCBHYCAQEwgckwgbQx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEfMB0GA1UECxMW
# VmVyaVNpZ24gVHJ1c3QgTmV0d29yazE7MDkGA1UECxMyVGVybXMgb2YgdXNlIGF0
# IGh0dHBzOi8vd3d3LnZlcmlzaWduLmNvbS9ycGEgKGMpMTAxLjAsBgNVBAMTJVZl
# cmlTaWduIENsYXNzIDMgQ29kZSBTaWduaW5nIDIwMTAgQ0ECEALkP4sOx0vPKKOs
# 70WV72swCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFJfVq8VpccoUspOlIQ8Zpe7G8XByMA0GCSqG
# SIb3DQEBAQUABIIBADyz6Vf1X5hxGKoCCTXQs038iglUQGgh/frjmgK1EpOR9Vm6
# ozTaZNsp3uEt+u0T4ziBXh+6CgfaJwW8rwUeeeE7EDc4R2AxOpvCDntAd9+VVWWJ
# +hP2l20LJWJ6GLP5L2faKGn7OjFl8XIhvOmC7B+NJkw4OosQxC+wkFJYpGpavuyH
# 0lEgYHHsbsckTDSpe/pqH4EzJZKKE1yBGuyhPW20qROZ9+AnI2Mw9SBHTFIUD/6d
# wsJPYxYFFXGLf7TyCBUbqxz898Gi5kBLeZ3xckt27MVhQuW8y+JHbJoqV1LSIBEk
# j+AJwGAI2goo5UQBg6d/79RqZmIehzPRVHiSSgyhggILMIICBwYJKoZIhvcNAQkG
# MYIB+DCCAfQCAQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMg
# Q29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2Vy
# dmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJ
# KoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTMxMDI5MTMz
# NDU2WjAjBgkqhkiG9w0BCQQxFgQUZ4afCfXg5KtsI4zlblY+2VwvLJIwDQYJKoZI
# hvcNAQEBBQAEggEAfVlVPAnKWqGs3uOl16F0JggGfKeRyfRD/FBXGFhZ0VVrBYAC
# uZ2Qz13HEPX1itxwnKhtRA8I6dhjh3nULGnKupuMOVhMdwQaWZQRoLNPdrQPoM6S
# dUPzxW6Qy1HAVWYCg2s5lBqNJOzGx12/qX/8P25JvX9R25rJ7LihulHSip2GHG/u
# ZeE0u7f/8D+XFOEVgdJLuTjv2rSerOqP1OZYqrjF2No2SQBy0g6yiF0NS+8GvLfM
# KOP5NaAQk93bdZ4iTU9qoXU9rRyWcq6X6EBV2uNFNl/0IqbHT5CG3I80Sde6bCbJ
# 3zePZ2TYzyhOtSjFK01V44CZUZdcsoKQ3Zkl5Q==
# SIG # End signature block
