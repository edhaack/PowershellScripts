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
#requires -version 2
<#
.SYNOPSIS
  <Overview of script>

.DESCRIPTION
  <Brief description of script>

.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>

.INPUTS
  <Inputs if any, otherwise state None>

.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>

.NOTES
  Version:        1.0
  Author:         E.S.H.
  Creation Date:  $((get-date).ToShortDateString())
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

#Param (
#	[Parameter(Mandatory=`$true)]
#	[AllowEmptyString()]
#	[string] `$parameterName
#)

`$scriptPath = split-path -parent `$MyInvocation.MyCommand.Definition
`$scriptName = `$MyInvocation.MyCommand.Name
`$startTime = Get-Date
`$timeDateStamp = `$(Get-Date -f yyyy-MM-dd.HH.mm)
`$logFile = "`$scriptName-`$timeDateStamp.log"
`$doOutputFile = `$false
#For Exceptions
`$shouldSendEmailOnException = `$false
`$smtpServer = "smtp.xceligent.org"
`$emailFrom = "teamcity@xceligent.com"
`$emailTo = "ehaack@xceligent.com"

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
`$ErrorActionPreference = `"SilentlyContinue`"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
`$sScriptVersion = `"1.0`"

#-----------------------------------------------------------[Functions - Script Specific]------------------------------------------


#-----------------------------------------------------------[Functions - Core]-----------------------------------------------------

Function Main {
	#Begin primary code.
	`$errorCode = 0
	try {
	
	}
	catch {
		HandleException `$_ 
		`$errorCode = 1
	}
	finally {
	
	}
	if(!(`$errorCode -eq 0)) {
		Write-Host "Exiting with error `$errorCode"
		exit `$errorCode 
	}
}

function HandleException(`$exceptionObject) {
	`$errorMessageBuilder = New-Object System.Text.StringBuilder
	`$errorMessageBuilder.Append("`$scriptName : An error occurred``r``n``r``n")
	`$errorMessageBuilder.Append("Exception Type: `$(`$exceptionObject.Exception.GetType().FullName)``r``n")
	`$errorMessageBuilder.Append("Exception Message: `$(`$exceptionObject.Exception.Message)``r``n")
	`$errorMessageBuilder.Append("``r``n")

	`$errorMessage = `$errorMessageBuilder.ToString()

    Write-Host "Caught an exception:" -ForegroundColor Red
	Write-Host `$errorMessage -ForegroundColor Red
	
	if(`$shouldSendEmailOnException -eq `$true){
		Write-Host "Sending email to: `$emailTo"
		
		`$emailMessage = New-Object System.Net.Mail.MailMessage( `$emailFrom , `$emailTo )
		`$emailMessage.Subject = "{0}-{1} Failure" -f `$scriptPath, `$scriptName
		`$emailMessage.IsBodyHtml = `$false
		`$emailMessage.Body = `$errorMessage

		`$SMTPClient = New-Object System.Net.Mail.SmtpClient( `$smtpServer )
		`$SMTPClient.Send( `$emailMessage )
	}
}

function ShowScriptBegin() {
	cls
	if(`$doOutputFile){
		Start-Transcript -path `$logFile -append
	}
	"
	Script Start-Time: `$startTime
	"
}

function ShowScriptEnd() {
	`$endTime = Get-Date
	`$elapsedTime = `$endTime - `$startTime
	"
	Complete at: `$endTime

	Duration:
	{2} hours, {0} minute(s) and {1} second(s)" -f `$elapsedTime.Minutes, `$elapsedTime.Seconds, `$elapsedTime.Hours
	if(`$doOutputFile){
		Stop-Transcript
	}
	
#	Write-Host "Press any key to continue ..."
#	`$x = `$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

ShowScriptBegin
Main
ShowScriptEnd

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
