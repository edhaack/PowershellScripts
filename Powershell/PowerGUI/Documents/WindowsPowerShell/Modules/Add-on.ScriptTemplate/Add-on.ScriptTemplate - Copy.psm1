#######################################################################################################################
# File:             Add-on.ScriptTemplate.psm1                                                                        #
# Author:           Jan Egil Ring                                                                                     #
# Publisher:                                                                                                          #
# Copyright:        © 2011 . All rights reserved.                                                                     #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   3. Check the Add-on.ScriptTemplate module.                                                        #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this:                 #
#                       Import-Module -Name Add-on.ScriptTemplate                                                     #
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

$minimumPowerGUIVersion = [System.Version]'2.4.0.1659'

if ($Host.Name –ne 'PowerGUIScriptEditorHost') {
	return
}

if ($Host.Version -lt $minimumPowerGUIVersion) {
	[System.Windows.Forms.MessageBox]::Show([PowerShellTypeExtensions.Win32Window]::CurrentWindow,"The ""$(Split-Path -Path $PSScriptRoot -Leaf)"" Add-on module requires version $minimumPowerGUIVersion or later of the Script Editor. The current Script Editor version is $($Host.Version).$([System.Environment]::NewLine * 2)Please upgrade to version $minimumPowerGUIVersion and try again.","Version $minimumPowerGUIVersion or later is required",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
	return
}

$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

#endregion

#region Load resources from disk.

$iconLibrary = @{
	# TODO: Load icons into this table.
	#       eg. ScriptTemplateIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ScriptTemplate.ico",16,16
	#           ScriptTemplateIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ScriptTemplate.ico",32,32
}

$imageLibrary = @{
	# TODO: Load images into this table.
	#       eg. ScriptTemplateImage16 = $iconLibrary['ScriptTemplateIcon16'].ToBitmap()
	#           ScriptTemplateImage32 = $iconLibrary['ScriptTemplateIcon32'].ToBitmap()
}

#endregion

$insertTemplateEventHandler = [EventHandler]{
	$template = @"
<#
===========================================================================
PURPOSE:

OVERVIEW:
1)
2)
3)

CREATED:
1.0 $((get-date).ToShortDateString()) - ESH - Initial release

UPDATED:
===========================================================================
#>

"@
	$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
	$pgse.CurrentDocumentWindow.Document.Text = $template
}

#region Get the New command.

$NewCommand = $pgse.Commands['FileCommand.New']
$NewCommand.add_Invoked($insertTemplateEventHandler)

#endregion

#region Clean-up the Add-on when it is removed.

$ExecutionContext.SessionState.Module.OnRemove = {
	$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

	$NewCommand.remove_Invoked($insertTemplateEventHandler)
}

#endregion
