#######################################################################################################################
# File:             Add-on.PowerGUIOnline.psm1                                                                        #
# Author:           Kirk Munro                                                                                        #
# Publisher:        Quest Software, Inc.                                                                              #
# Copyright:        © 2010 Quest Software, Inc. All rights reserved.                                                  #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   3. Check the Add-on.PowerGUIOnline module.                                                        #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this:                 #
#                       Import-Module -Name Add-on.PowerGUIOnline                                                     #
#                   Please provide feedback on the PowerGUI Forums.                                                   #
#######################################################################################################################

Set-StrictMode -Version 2

#region Initialize the Script Editor Add-on.

if ($Host.Name –ne 'PowerGUIScriptEditorHost') { return }
if ($Host.Version -lt '2.1.1.1202') {
	[System.Windows.Forms.MessageBox]::Show("The ""$(Split-Path -Path $PSScriptRoot -Leaf)"" Add-on module requires version 2.2.0.1348 or later of the Script Editor. The current Script Editor version is $($Host.Version).$([System.Environment]::NewLine * 2)Please upgrade to version 2.2.0.1348 and try again.","Version 2.2.0.1348 or later is required",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
	return
}

$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

#endregion

#region Load resources from disk.

$iconLibrary = @{
	PowerGUIOnlineIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\PowerGUIOnline.ico",16,16
	PowerGUIOnlineIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\PowerGUIOnline.ico",32,32
	PowerGUIIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\PowerGUI.ico",16,16
	PowerGUIIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\PowerGUI.ico",32,32
	ContestIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\PowerGUI.ico",16,16
	ContestIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\PowerGUI.ico",32,32
	ContestDetailsIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ContestDetails.ico",16,16
	ContestDetailsIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ContestDetails.ico",32,32
	ContestFolderIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ContestFolder.ico",16,16
	OnlineHelpIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\OnlineHelp.ico",16,16
	OnlineHelpIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\OnlineHelp.ico",32,32
	RequestScriptIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\RequestScriptOnline.ico",16,16
	RequestScriptIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\RequestScriptOnline.ico",32,32
	YouTubeIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\YouTube.ico",16,16
	AddonIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ScriptEditorAddon.ico",16,16
	AddonIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ScriptEditorAddon.ico",32,32
	PowerPackIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\PowerPack.ico",16,16
	PowerPackIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\PowerPack.ico",32,32
	ActiveDirectoryPowerPacksIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ActiveDirectoryPowerPacks.ico",16,16
	ActiveDirectoryPowerPacksIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ActiveDirectoryPowerPacks.ico",32,32
	ExchangePowerPacksIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ExchangePowerPacks.ico",16,16
	ExchangePowerPacksIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ExchangePowerPacks.ico",32,32
	IISPowerPacksIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\IISPowerPacks.ico",16,16
	IISPowerPacksIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\IISPowerPacks.ico",32,32
	LyncPowerPacksIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\LyncPowerPacks.ico",16,16
	LyncPowerPacksIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\LyncPowerPacks.ico",32,32
	PowerShellPowerPacksIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\PowerShellPowerPacks.ico",16,16
	PowerShellPowerPacksIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\PowerShellPowerPacks.ico",32,32
	ReportingPowerPacksIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ReportingPowerPacks.ico",16,16
	ReportingPowerPacksIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ReportingPowerPacks.ico",32,32
	SecurityPowerPacksIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SecurityPowerPacks.ico",16,16
	SecurityPowerPacksIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SecurityPowerPacks.ico",32,32
	SharePointPowerPacksIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SharePointPowerPacks.ico",16,16
	SharePointPowerPacksIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SharePointPowerPacks.ico",32,32
	SocialMediaPowerPacksIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SocialMediaPowerPacks.ico",16,16
	SocialMediaPowerPacksIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SocialMediaPowerPacks.ico",32,32
	SQLPowerPacksIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SQLPowerPacks.ico",16,16
	SQLPowerPacksIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SQLPowerPacks.ico",32,32
	SystemCenterPowerPacksIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SystemCenterPowerPacks.ico",16,16
	SystemCenterPowerPacksIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SystemCenterPowerPacks.ico",32,32
	VirtualizationPowerPacksIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\VirtualizationPowerPacks.ico",16,16
	VirtualizationPowerPacksIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\VirtualizationPowerPacks.ico",32,32
	WindowsServerPowerPacksIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\WindowsServerPowerPacks.ico",16,16
	WindowsServerPowerPacksIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\WindowsServerPowerPacks.ico",32,32
	TwitterIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\Twitter.ico",16,16
	TwitterIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\Twitter.ico",32,32
	VisualStudioIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\VisualStudio.ico",16,16
	VisualStudioIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\VisualStudio.ico",32,32
	PowerGUIVSXIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\PowerGUIVSX.ico",16,16
	PowerGUIVSXIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\PowerGUIVSX.ico",32,32
	WallpaperIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\Wallpaper.ico",16,16
	WallpaperIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\Wallpaper.ico",32,32
}

$imageLibrary = @{
	PowerGUIOnlineImage16 = $iconLibrary['PowerGUIOnlineIcon16'].ToBitmap()
	PowerGUIOnlineImage32 = $iconLibrary['PowerGUIOnlineIcon32'].ToBitmap()
	PowerGUIImage16 = $iconLibrary['PowerGUIIcon16'].ToBitmap()
	PowerGUIImage32 = $iconLibrary['PowerGUIIcon32'].ToBitmap()
	ContestImage16 = $iconLibrary['ContestIcon16'].ToBitmap()
	ContestImage32 = $iconLibrary['ContestIcon32'].ToBitmap()
	ContestDetailsImage16 = $iconLibrary['ContestDetailsIcon16'].ToBitmap()
	ContestDetailsImage32 = $iconLibrary['ContestDetailsIcon32'].ToBitmap()
	ContestFolderImage16 = $iconLibrary['ContestFolderIcon16'].ToBitmap()
	OnlineHelpImage16 = $iconLibrary['OnlineHelpIcon16'].ToBitmap()
	OnlineHelpImage32 = $iconLibrary['OnlineHelpIcon32'].ToBitmap()
	RequestScriptImage16 = $iconLibrary['RequestScriptIcon16'].ToBitmap()
	RequestScriptImage32 = $iconLibrary['RequestScriptIcon32'].ToBitmap()
	YouTubeImage16 = $iconLibrary['YouTubeIcon16'].ToBitmap()
	AddonImage16 = $iconLibrary['AddonIcon16'].ToBitmap()
	AddonImage32 = $iconLibrary['AddonIcon32'].ToBitmap()
	PowerPackImage16 = $iconLibrary['PowerPackIcon16'].ToBitmap()
	PowerPackImage32 = $iconLibrary['PowerPackIcon32'].ToBitmap()
	ActiveDirectoryPowerPacksImage16 = $iconLibrary['ActiveDirectoryPowerPacksIcon16'].ToBitmap()
	ActiveDirectoryPowerPacksImage32 = $iconLibrary['ActiveDirectoryPowerPacksIcon32'].ToBitmap()
	ExchangePowerPacksImage16 = $iconLibrary['ExchangePowerPacksIcon16'].ToBitmap()
	ExchangePowerPacksImage32 = $iconLibrary['ExchangePowerPacksIcon32'].ToBitmap()
	IISPowerPacksImage16 = $iconLibrary['IISPowerPacksIcon16'].ToBitmap()
	IISPowerPacksImage32 = $iconLibrary['IISPowerPacksIcon32'].ToBitmap()
	LyncPowerPacksImage16 = $iconLibrary['LyncPowerPacksIcon16'].ToBitmap()
	LyncPowerPacksImage32 = $iconLibrary['LyncPowerPacksIcon32'].ToBitmap()
	PowerShellPowerPacksImage16 = $iconLibrary['PowerShellPowerPacksIcon16'].ToBitmap()
	PowerShellPowerPacksImage32 = $iconLibrary['PowerShellPowerPacksIcon32'].ToBitmap()
	ReportingPowerPacksImage16 = $iconLibrary['ReportingPowerPacksIcon16'].ToBitmap()
	ReportingPowerPacksImage32 = $iconLibrary['ReportingPowerPacksIcon32'].ToBitmap()
	SecurityPowerPacksImage16 = $iconLibrary['SecurityPowerPacksIcon16'].ToBitmap()
	SecurityPowerPacksImage32 = $iconLibrary['SecurityPowerPacksIcon32'].ToBitmap()
	SharePointPowerPacksImage16 = $iconLibrary['SharePointPowerPacksIcon16'].ToBitmap()
	SharePointPowerPacksImage32 = $iconLibrary['SharePointPowerPacksIcon32'].ToBitmap()
	SocialMediaPowerPacksImage16 = $iconLibrary['SocialMediaPowerPacksIcon16'].ToBitmap()
	SocialMediaPowerPacksImage32 = $iconLibrary['SocialMediaPowerPacksIcon32'].ToBitmap()
	SQLPowerPacksImage16 = $iconLibrary['SQLPowerPacksIcon16'].ToBitmap()
	SQLPowerPacksImage32 = $iconLibrary['SQLPowerPacksIcon32'].ToBitmap()
	SystemCenterPowerPacksImage16 = $iconLibrary['SystemCenterPowerPacksIcon16'].ToBitmap()
	SystemCenterPowerPacksImage32 = $iconLibrary['SystemCenterPowerPacksIcon32'].ToBitmap()
	VirtualizationPowerPacksImage16 = $iconLibrary['VirtualizationPowerPacksIcon16'].ToBitmap()
	VirtualizationPowerPacksImage32 = $iconLibrary['VirtualizationPowerPacksIcon32'].ToBitmap()
	WindowsServerPowerPacksImage16 = $iconLibrary['WindowsServerPowerPacksIcon16'].ToBitmap()
	WindowsServerPowerPacksImage32 = $iconLibrary['WindowsServerPowerPacksIcon32'].ToBitmap()
	TwitterImage16 = $iconLibrary['TwitterIcon16'].ToBitmap()
	TwitterImage32 = $iconLibrary['TwitterIcon32'].ToBitmap()
	VisualStudioImage16 = $iconLibrary['VisualStudioIcon16'].ToBitmap()
	VisualStudioImage32 = $iconLibrary['VisualStudioIcon32'].ToBitmap()
	PowerGUIVSXImage16 = $iconLibrary['PowerGUIVSXIcon16'].ToBitmap()
	PowerGUIVSXImage32 = $iconLibrary['PowerGUIVSXIcon32'].ToBitmap()
	WallpaperImage16 = $iconLibrary['WallpaperIcon16'].ToBitmap()
	WallpaperImage32 = $iconLibrary['WallpaperIcon32'].ToBitmap()
}

#endregion

#region Define helper variables.

$powerGUIUrl = @(
	New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'Home',@{DisplayText='&Home';Image='PowerGUIImage16';Type='Entry';URL='http://www.powergui.org'}
	New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'Contest',@{DisplayText='&Contest';Image='ContestImage16';Type='Submenu';Contents=@(
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'ContestDetails',@{DisplayText='&Details';Image='ContestDetailsImage16';Type='Entry';URL='http://www.powergui.org/contest.jspa'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'ContestEntryFolder',@{DisplayText='&Entry folder';Image='ContestFolderImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=389'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'ContestAuthoringToolkit',@{DisplayText='Authoring &Toolkit Add-on';Image='AddonImage16';Type='Entry';URL='http://www.powergui.org/entry.jspa?externalID=2893&categoryID=387'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'ContestAddonTutorial',@{DisplayText='How to create an &Add-on';Image='OnlineHelpImage16';Type='Entry';URL='http://www.powergui.org/entry.jspa?externalID=2894&categoryID=387'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'ContestPowerPackTutorial',@{DisplayText='How to create a &PowerPack';Image='OnlineHelpImage16';Type='Entry';URL='http://wiki.powergui.org/index.php/PowerPacks#Creating_a_PowerPack'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'ContestQuestion',@{DisplayText='Ask a &question';Image='OnlineHelpImage16';Type='Entry';URL='http://www.powergui.org/forum.jspa?forumID=800'}
	)}
	New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'RequestAScript',@{DisplayText='Request a &script';Image='RequestScriptImage16';Type='Entry';URL='http://www.powergui.org/forum.jspa?forumID=165'}
	New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'LearningCenter',@{DisplayText='&Learning center';Image='OnlineHelpImage16';Type='Submenu';Contents=@(
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'Wiki',@{DisplayText='&Wiki';Image='OnlineHelpImage16';Type='Entry';URL='http://wiki.powergui.org/'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'PoshoholicBlog',@{DisplayText='&Poshoholic blog';Image='OnlineHelpImage16';Type='Entry';URL='http://poshoholic.com/'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'DmitrysPowerBlog',@{DisplayText='&Dmitry''s PowerBlog';Image='OnlineHelpImage16';Type='Entry';URL='http://dmitrysotnikov.wordpress.com/'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'Tutorials',@{DisplayText='&Tutorials';Image='OnlineHelpImage16';Type='Entry';URL='http://www.powergui.org/tutorials.jspa'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'Screencasts',@{DisplayText='&Screencasts';Image='YouTubeImage16';Type='Entry';URL='http://www.youtube.com/user/questsoftware#grid/user/807CCBBC67873456'}
	)}
	New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'Forums',@{DisplayText='&Discussion forums';Image='OnlineHelpImage16';Type='Submenu';Contents=@(
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'GeneralForum',@{DisplayText='&General';Image='OnlineHelpImage16';Type='Entry';URL='http://www.powergui.org/forum.jspa?forumID=118'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'ActiveDirectoryForum',@{DisplayText='&Active Directory';Image='OnlineHelpImage16';Type='Entry';URL='http://www.powergui.org/forum.jspa?forumID=173'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'SharePointForum',@{DisplayText='&SharePoint';Image='OnlineHelpImage16';Type='Entry';URL='http://www.powergui.org/forum.jspa?forumID=886'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'VirtualizationForum',@{DisplayText='&Virtualization';Image='OnlineHelpImage16';Type='Entry';URL='http://www.powergui.org/forum.jspa?forumID=853'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'MobileShellForum',@{DisplayText='&MobileShell';Image='OnlineHelpImage16';Type='Entry';URL='http://www.powergui.org/forum.jspa?forumID=885'}
	)}
	New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'Addons',@{DisplayText='&Add-ons';Image='AddonImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=387'}
	New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'PowerPacks',@{DisplayText='&PowerPacks';Image='PowerPackImage16';Type='Submenu';Contents=@(
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'ActiveDirectoryPowerPacks',@{DisplayText='&Active Directory';Image='ActiveDirectoryPowerPacksImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=46'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'ExchangePowerPacks',@{DisplayText='&Exchange Server';Image='ExchangePowerPacksImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=47'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'IISPowerPacks',@{DisplayText='&IIS';Image='IISPowerPacksImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=392'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'LyncPowerPacks',@{DisplayText='OCS or &Lync Server';Image='LyncPowerPacksImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=47'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'PowerShellPowerPacks',@{DisplayText='&PowerShell';Image='PowerShellPowerPacksImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=55'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'ReportingPowerPacks',@{DisplayText='&Reporting';Image='ReportingPowerPacksImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=52'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'SecurityPowerPacks',@{DisplayText='&Security';Image='SecurityPowerPacksImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=388'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'SharePointPowerPacks',@{DisplayText='S&harePoint';Image='SharePointPowerPacksImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=354'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'SocialMediaPowerPacks',@{DisplayText='Social &media';Image='SocialMediaPowerPacksImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=56'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'SQLServerPowerPacks',@{DisplayText='S&QL Server';Image='SQLPowerPacksImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=54'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'SystemCenterPowerPacks',@{DisplayText='System &Center';Image='SystemCenterPowerPacksImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=49'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'VirtualizationPowerPacks',@{DisplayText='&Virtualization';Image='VirtualizationPowerPacksImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=290'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'WindowsServerPowerPacks',@{DisplayText='&Windows Server';Image='WindowsServerPowerPacksImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=53'}
	)}
	New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'Twitter',@{DisplayText='&Twitter';Image='TwitterImage16';Type='Submenu';Contents=@(
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'PowerGUIOnTwitter',@{DisplayText='@power&guiorg';Image='TwitterImage16';Type='Entry';URL='http://www.twitter.com/powerguiorg'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'PoshoholicOnTwitter',@{DisplayText='@&poshoholic';Image='TwitterImage16';Type='Entry';URL='http://www.twitter.com/poshoholic'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'DmitryOnTwitter',@{DisplayText='@&dsotnikov';Image='TwitterImage16';Type='Entry';URL='http://www.twitter.com/dsotnikov'}
	)}
	New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'DeveloperResources',@{DisplayText='De&veloper resources';Image='VisualStudioImage16';Type='Submenu';Contents=@(
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'PowerGUIVSX',@{DisplayText='&PowerGUI VSX';Image='PowerGUIVSXImage16';Type='Entry';URL='http://powerguivsx.codeplex.com/'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'AdamDriscollOnTwitter',@{DisplayText='@&adamdriscoll';Image='TwitterImage16';Type='Entry';URL='http://www.twitter.com/adamdriscoll'}
		New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'CSharpeningBlog',@{DisplayText='&CSharpening Blog';Image='OnlineHelpImage16';Type='Entry';URL='http://www.csharpening.net/blog/'}
	)}
	New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'Wallpaper',@{DisplayText='Desktop &wallpaper';Image='WallpaperImage16';Type='Entry';URL='http://www.powergui.org/kbcategory.jspa?categoryID=393'}
	New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'YouTubeChannel',@{DisplayText='&YouTube channel';Image='YouTubeImage16';Type='Entry';URL='http://www.youtube.com/user/questsoftware#grid/user/807CCBBC67873456'}
	New-Object -TypeName System.Collections.DictionaryEntry -ArgumentList 'Feedback',@{DisplayText='&Feedback';Image='OnlineHelpImage16';Type='Entry';URL='http://www.powergui.org/forum.jspa?forumID=162'}
)

#endregion

#region Determine if the script is running in STA mode.

$staMode = ([System.Threading.Thread]::CurrentThread.ApartmentState -eq [System.Threading.ApartmentState]::STA)

#endregion

#region Create and/or initialize the web browser window when using STA mode.

if ($staMode) {
	if (-not ($PowerGUIOnlineWindow = $pgse.ToolWindows['PowerGUIOnline'])) {
		$PowerGUIOnlineWindow = $pgse.ToolWindows.Add('PowerGUIOnline')
		$PowerGUIOnlineWindow.Title = 'Power&GUI Online' -replace '&'
		$PowerGUIOnlineWindow.Control = New-Object -TypeName System.Windows.Forms.WebBrowser
		$PowerGUIOnlineWindow.Control.Invoke([EventHandler]{$PowerGUIOnlineWindow.Control.Navigate($powerGUIUrl[0].Value.URL)})
		$PowerGUIOnlineWindow.Control.Invoke([EventHandler]{$PowerGUIOnlineWindow.Control.Parent.State = 'TabbedDocument'})
		$PowerGUIOnlineWindow.Visible = $true
		$PowerGUIOnlineWindow.Control.Invoke([EventHandler]{$PowerGUIOnlineWindow.Control.Parent.Activate($true)})
	} else {
		if ($PowerGUIOnlineWindow.Control -isnot [System.Windows.Forms.WebBrowser]) {
			$PowerGUIOnlineWindow.Control = New-Object System.Windows.Forms.WebBrowser
		}
		$PowerGUIOnlineWindow.Control.Invoke([EventHandler]{$PowerGUIOnlineWindow.Control.Navigate($powerGUIUrl[0].Value.URL)})
	}
} else {
	Start-Process -FilePath $powerGUIUrl[0].Value.URL
}

#endregion

#region Create a Go menu command to activate the web browser window if STA mode is enabled.

if ($staMode -and
    (-not ($goToPowerGUIOnlineCommand = $pgse.Commands['GoCommand.PowerGUIOnline']))) {
	$goToPowerGUIOnlineCommand = New-Object -TypeName Quest.PowerGUI.SDK.ItemCommand -ArgumentList 'GoCommand', 'PowerGUIOnline'
	$goToPowerGUIOnlineCommand.Text = 'Power&GUI Online'
	$goToPowerGUIOnlineCommand.Image = $imageLibrary['PowerGUIOnlineImage16']
	if ($goMenu = $pgse.Menus['MenuBar.Go']) {
		$index = $goMenu.Items.Count + 1
		if ($index -lt 10) {
			$goToPowerGUIOnlineCommand.AddShortcut("Ctrl+${index}")
		}
	}
	$goToPowerGUIOnlineCommand.ScriptBlock = {
		$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
		if ($PowerGUIOnlineWindow = $pgse.ToolWindows['PowerGUIOnline']) {
			$PowerGUIOnlineWindow.Visible = $true
			$PowerGUIOnlineWindow.Control.Invoke([EventHandler]{$PowerGUIOnlineWindow.Control.Parent.Activate($true)})
		}
	}

	$pgse.Commands.Add($goToPowerGUIOnlineCommand)
}

#endregion

#region Add the Go to PowerGUIOnline command to the Go menu.

if ($staMode -and ($goMenu = $pgse.Menus['MenuBar.Go'])) {
	$goMenu.Items.Add($goToPowerGUIOnlineCommand)
}

#endregion

#region Create the PowerGUIOnline menu.

if (-not ($PowerGUIOnlineMenu = $pgse.Menus['MenuBar.PowerGUIOnline'])) {
	$PowerGUIOnlineMenuCommand = New-Object -TypeName Quest.PowerGUI.SDK.MenuCommand -ArgumentList 'MenuBar','PowerGUIOnline'
	$PowerGUIOnlineMenuCommand.Text = '&PowerGUI Online'
	$index = -1
	if ($HelpMenu = $pgse.Menus['MenuBar.Help']) {
		$index = $pgse.Menus.IndexOf($HelpMenu)
	}
	if ($index -ge 0) {
		$pgse.Menus.Insert($index,$PowerGUIOnlineMenuCommand)
	} else {
		$pgse.Menus.Add($PowerGUIOnlineMenuCommand)
	}
	$PowerGUIOnlineMenu = $pgse.Menus['MenuBar.PowerGUIOnline']
}

#endregion

#region Iterate through the link collection to build the menu items.

$processCollectionScriptBlock = {
	param(
		[System.Array]$Collection,
		[System.Object]$Parent
	)

	foreach ($item in $Collection) {
		if ($item.Value.Type -eq 'Entry') {
			#region Create the menu item in the submenu.

			if (-not ($menuItem = $Parent.Items["PowerGUIOnlineCommand.$($item.Key)"])) {
				if (-not ($command = $pgse.Commands["PowerGUIOnlineCommand.$($item.Key)"])) {
					$command = New-Object -TypeName Quest.PowerGUI.SDK.ItemCommand -ArgumentList 'PowerGUIOnlineCommand',$item.Key
					$command.Text = $item.Value.DisplayText
					$command.Image = $imageLibrary[$item.Value.Image]
					$scriptBlock = @"
`$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
if (`$PowerGUIOnlineWindow = `$pgse.ToolWindows['PowerGUIOnline']) {
	`$PowerGUIOnlineWindow.Visible = `$true
	`$PowerGUIOnlineWindow.Control.Invoke([EventHandler]{`$PowerGUIOnlineWindow.Control.Parent.Activate(`$true)})
	`$PowerGUIOnlineWindow.Control.Invoke([EventHandler]{`$PowerGUIOnlineWindow.Control.Navigate('$($item.Value.URL)')})
} else {
	Start-Process -FilePath '$($item.Value.URL)'
}
"@
					$command.ScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock($scriptBlock)
					$pgse.Commands.Add($command)
				}
				$Parent.Items.Add($command)
			}

			#endregion
		} else {
			#region Create the submenu.

			if (($PowerGUIOnlineMenu = $pgse.Menus['MenuBar.PowerGUIOnline']) -and
			    (-not ($submenu = $PowerGUIOnlineMenu.Items["PowerGUIOnlineCommand.$($item.Key)"]))) {
				$command = New-Object -TypeName Quest.PowerGUI.SDK.MenuCommand -ArgumentList 'PowerGUIOnlineCommand',$item.Key
				$command.Text = $item.Value.DisplayText
				$command.Image = $imageLibrary[$item.Value.Image]
				$pgse.Commands.Add($command)
				$PowerGUIOnlineMenu.Items.Add($command)
			    $submenu = $PowerGUIOnlineMenu.Items["PowerGUIOnlineCommand.$($item.Key)"]
			}

			#endregion
			#region Then process the collection of entries for the submenu

			& $processCollectionScriptBlock -Collection $item.Value.Contents -Parent $submenu

			#endregion
		}
	}
}

& $processCollectionScriptBlock -Collection $powerGUIUrl -Parent $PowerGUIOnlineMenu

#endregion

#region Clean-up the Add-on when it is removed.

$ExecutionContext.SessionState.Module.OnRemove = {
	$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

	#region Remove the PowerGUIOnline menu.

	if ($PowerGUIOnlineMenu = $pgse.Menus['MenuBar.PowerGUIOnline']) {
		$removeMenuItemScriptBlock = {
			param(
				[Quest.PowerGUI.SDK.BarItem]$MenuItem,
				[Quest.PowerGUI.SDK.BarMenu]$Parent
			)
			if ($MenuItem -is [Quest.PowerGUI.SDK.BarMenu]) {
				foreach ($item in  @($MenuItem.Items)) {
					& $removeMenuItemScriptBlock -Parent $MenuItem -MenuItem $item
				}
			}
			$commandName = $MenuItem.Command.FullName
			if ($Parent -ne $null) {
				$Parent.Items.Remove($MenuItem) | Out-Null
			} else {
				$pgse.Menus.Remove($MenuItem) | Out-Null
			}
			if ($command = $pgse.Commands[$commandName]) {
				$pgse.Commands.Remove($command) | Out-Null
			}
		}
		& $removeMenuItemScriptBlock -MenuItem $PowerGUIOnlineMenu
	}

	#endregion

	#region Remove the PowerGUIOnline menu item from the Go menu.

	if (($goMenu = $pgse.Menus['MenuBar.Go']) -and
		($goToPowerGUIOnlineMenuItem = $goMenu.Items['GoCommand.PowerGUIOnline'])) {
		$goMenu.Items.Remove($goToPowerGUIOnlineMenuItem) | Out-Null
	}

	#endregion

	#region Remove the Go to PowerGUIOnline command.

	if ($goToPowerGUIOnlineCommand = $pgse.Commands['GoCommand.PowerGUIOnline']) {
		$pgse.Commands.Remove($goToPowerGUIOnlineCommand) | Out-Null
	}

	#endregion

	#region Remove the PowerGUIOnline window.

	if ($PowerGUIOnlineWindow = $pgse.ToolWindows['PowerGUIOnline']) {
		$pgse.ToolWindows.Remove($PowerGUIOnlineWindow) | Out-Null
	}

	#endregion
}

#endregion

# SIG # Begin signature block
# MIISlAYJKoZIhvcNAQcCoIIShTCCEoECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgVGiAHGa4hXc1T+N/1fBEsW/
# XX6gghBsMIIDdTCCAl2gAwIBAgILBAAAAAABFUtaw5QwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw05ODA5
# MDExMjAwMDBaFw0yODAxMjgxMjAwMDBaMFcxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290IENBMRswGQYDVQQDExJH
# bG9iYWxTaWduIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDaDuaZjc6j40+Kfvvxi4Mla+pIH/EqsLmVEQS98GPR4mdmzxzdzxtIK+6NiY6a
# rymAZavpxy0Sy6scTHAHoT0KMM0VjU/43dSMUBUc71DuxC73/OlS8pF94G3VNTCO
# XkNz8kHp1Wrjsok6Vjk4bwY8iGlbKk3Fp1S4bInMm/k8yuX9ifUSPJJ4ltbcdG6T
# RGHRjcdGsnUOhugZitVtbNV4FpWi6cgKOOvyJBNPc1STE4U6G7weNLWLBYy5d4ux
# 2x8gkasJU26Qzns3dLlwR5EiUWMWea6xrkEmCMgZK9FGqkjWZCrXgzT/LCrBbBlD
# SgeF59N89iFo7+ryUp9/k5DPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
# HRMBAf8EBTADAQH/MB0GA1UdDgQWBBRge2YaRQ2XyolQL30EzTSo//z9SzANBgkq
# hkiG9w0BAQUFAAOCAQEA1nPnfE920I2/7LqivjTFKDK1fPxsnCwrvQmeU79rXqoR
# SLblCKOzyj1hTdNGCbM+w6DjY1Ub8rrvrTnhQ7k4o+YviiY776BQVvnGCv04zcQL
# cFGUl5gE38NflNUVyRRBnMRddWQVDf9VMOyGj/8N7yy5Y0b2qvzfvGn9LhJIZJrg
# lfCm7ymPAbEVtQwdpf5pLGkkeB6zpxxxYu7KyJesF12KwvhHhm4qxFYxldBniYUr
# +WymXUadDKqC5JlR3XC321Y9YeRq4VzW9v493kHMB65jUr9TU/Qr6cf9tveCX4XS
# QRjbgbMEHMUfpIBvFSDJ3gyICh3WZlXi/EjJKSZp4DCCBAcwggLvoAMCAQICCwEA
# AAAAAR5GQJ02MA0GCSqGSIb3DQEBBQUAMGMxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMRYwFAYDVQQLEw1PYmplY3RTaWduIENBMSEwHwYD
# VQQDExhHbG9iYWxTaWduIE9iamVjdFNpZ24gQ0EwHhcNMDgxMjE3MTc0ODAyWhcN
# MTExMjE3MTc0ODAyWjBhMQswCQYDVQQGEwJVUzEXMBUGA1UEChMOUXVlc3QgU29m
# dHdhcmUxFzAVBgNVBAMTDlF1ZXN0IFNvZnR3YXJlMSAwHgYJKoZIhvcNAQkBFhFz
# dXBwb3J0QHF1ZXN0LmNvbTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA1mza
# 2hKiiqZnaF1sHhuFRS7MEGq9tYhF7AFbJRvTvhCZk9sxK92thKBFyDSOzJauB7Zt
# j+1HwQzpqbbU94EsR09JOf8vB+xQKLCxaBP5YjwhjJzVy+1d6frVWYN1oVxPXRBM
# G7BnFgfRkOdtsg/Qn1Uqn1ENSozyjTuh5iduUy0CAwEAAaOCAUAwggE8MB8GA1Ud
# IwQYMBaAFNJb80smS6Ww5139Vn/28S44TlOgME4GCCsGAQUFBwEBBEIwQDA+Bggr
# BgEFBQcwAoYyaHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLm5ldC9jYWNlcnQvT2Jq
# ZWN0U2lnbi5jcnQwOQYDVR0fBDIwMDAuoCygKoYoaHR0cDovL2NybC5nbG9iYWxz
# aWduLm5ldC9PYmplY3RTaWduLmNybDAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIH
# gDATBgNVHSUEDDAKBggrBgEFBQcDAzBLBgNVHSAERDBCMEAGCSsGAQQBoDIBMjAz
# MDEGCCsGAQUFBwIBFiVodHRwOi8vd3d3Lmdsb2JhbHNpZ24ubmV0L3JlcG9zaXRv
# cnkvMBEGCWCGSAGG+EIBAQQEAwIEEDANBgkqhkiG9w0BAQUFAAOCAQEAG9hUuQek
# ddDJ/pzfqo9p4hzKBkeKcVsunEeTUMNg90XzgdOYRFJPCD7T+gXXrTs6Y2xFmLJN
# G/2lQsjQ/32cBBN9zZdbX+ExhFfEV9/w0gbw3H/PfYkCRvp9VZlTafIt4MJCt/Zp
# guPQgggpWadScg7jQNyeHEg6H6c3WHO8PMiKcKJp9LuM1PKX9Bjy6F2k8rbdEAyJ
# u0mIiAcnEAc/KwoKBZVT1gnT3rkwgTgNlXw2hqT/Zcf8Jy4IDzbKzL+gYmDCNaju
# wAzhzaA05oZTLwhFV1sdc5MSJVJnMJVLpNO1jrhi5g6Oo6EmezM/kE8nzoXbmTlP
# JjOApuATvUdFlzCCBA0wggL1oAMCAQICCwQAAAAAASOeD6yzMA0GCSqGSIb3DQEB
# BQUAMFcxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRAw
# DgYDVQQLEwdSb290IENBMRswGQYDVQQDExJHbG9iYWxTaWduIFJvb3QgQ0EwHhcN
# OTkwMTI4MTMwMDAwWhcNMTcwMTI3MTIwMDAwWjCBgTELMAkGA1UEBhMCQkUxGTAX
# BgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExJTAjBgNVBAsTHFByaW1hcnkgT2JqZWN0
# IFB1Ymxpc2hpbmcgQ0ExMDAuBgNVBAMTJ0dsb2JhbFNpZ24gUHJpbWFyeSBPYmpl
# Y3QgUHVibGlzaGluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AKKbdSqnE7oJcSQY36EGYikSntyedXPo31ZXaZYTVk/yyLwBWO0mhnILYPUZxVUD
# V5u5EMmh1HRA/2wA6OZTN/632nk+uFI46YEsnw4zUqbNcM5KXWL00WdevJdKB8q8
# 3Y1Hsc3xZVuFAbBLa97Nji71UOijnJ0mmGs2Y0EDcETwX+IldXlQfV+hBqJGDFWV
# RxTTkUaGaJnnJ/SU7JpBUfeW1HqM4USXaHED2FhvvbQQQu4NZnVGi0SW0jAAEgdj
# 90SbAXDKVm+cWJcqJxeLLnFSbUarpysPfxZIZMhS+gYXAAd010WzDPV4lXPoCu7E
# 4HKMHhGqHrtezvm0AO5zvc0CAwEAAaOBrjCBqzAOBgNVHQ8BAf8EBAMCAQYwDwYD
# VR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUFVF5GnwMWfnazdjEOhOayXgtf00wMwYD
# VR0fBCwwKjAooCagJIYiaHR0cDovL2NybC5nbG9iYWxzaWduLm5ldC9Sb290LmNy
# bDATBgNVHSUEDDAKBggrBgEFBQcDAzAfBgNVHSMEGDAWgBRge2YaRQ2XyolQL30E
# zTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEAtXimonwEt3/Jf31qvHH6KTBgwvRi
# Hv5/Qx6bbuKyH3MLhXZbffVOSQYv1Pq3kUDv7W+NjhODVMUqAj0KpNyZC3q9dy/M
# QMGP88SMTnK6EHzm/2Qrx85sp/zXmnyORo0Bg01CO9ucP58yYVfXF7CzNmbws/1E
# b4E3sZROp1YlifWK1m0RYmJ5XEKQAhjTnCP8COhkRbktfoBbTq/DiimSg3gfkUE0
# r4XF/QeZTixc/sf9F7slJTFNcrW1KUtImjdvE8cRTkpFHn4vMZyr6FKv1meXNIhf
# DidqZlLRWsesMCwgON0r/zrrzhBFgqJ7G6Egc1abKpPmBFEGbBvcL4mUkzCCBNMw
# ggO7oAMCAQICCwQAAAAAASOeD68kMA0GCSqGSIb3DQEBBQUAMIGBMQswCQYDVQQG
# EwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTElMCMGA1UECxMcUHJpbWFy
# eSBPYmplY3QgUHVibGlzaGluZyBDQTEwMC4GA1UEAxMnR2xvYmFsU2lnbiBQcmlt
# YXJ5IE9iamVjdCBQdWJsaXNoaW5nIENBMB4XDTA0MDEyMjEwMDAwMFoXDTE3MDEy
# NzEwMDAwMFowYzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYt
# c2ExFjAUBgNVBAsTDU9iamVjdFNpZ24gQ0ExITAfBgNVBAMTGEdsb2JhbFNpZ24g
# T2JqZWN0U2lnbiBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALCx
# 8oAAcM7sw4y0l+3GCYwmb4nfZ1mBz94UE0zCsUXiU3VB+gc2b7oRcCiUfG1yvQcV
# JWU6Cf+F3Pp7XjeHOOTHSwiAmJ6KzVgJAsDDAUmWWIiJJln1bca5wfsYJe3YYk7K
# CmxdcO/O05spCwnG9u62FtQ8VI7MXeCv290jCTJ7MoEWYgoGy3rPNCG2bza2sc7L
# mik1QD6dWHz/rYKY+rjVico13cvNVwbLm+S/lKiAmF93lvC256t0eUAhpmPp0AeR
# vYU4tK6WrKH/FHPapUW4TYbOKjzv1N8oDnWpqIgTwuR8YJPyJcwDhJfmTrafLda1
# izQ8q9U4Osg9xLH5lM0CAwEAAaOCAWcwggFjMA4GA1UdDwEB/wQEAwIBBjASBgNV
# HRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBTSW/NLJkulsOdd/VZ/9vEuOE5ToDBK
# BgNVHSAEQzBBMD8GCSsGAQQBoDIBMjAyMDAGCCsGAQUFBwIBFiRodHRwOi8vd3d3
# Lmdsb2JhbHNpZ24ubmV0L3JlcG9zaXRvcnkwOQYDVR0fBDIwMDAuoCygKoYoaHR0
# cDovL2NybC5nbG9iYWxzaWduLm5ldC9wcmltb2JqZWN0LmNybDBOBggrBgEFBQcB
# AQRCMEAwPgYIKwYBBQUHMAKGMmh0dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5uZXQv
# Y2FjZXJ0L1ByaW1PYmplY3QuY3J0MBEGCWCGSAGG+EIBAQQEAwIAATATBgNVHSUE
# DDAKBggrBgEFBQcDAzAfBgNVHSMEGDAWgBQVUXkafAxZ+drN2MQ6E5rJeC1/TTAN
# BgkqhkiG9w0BAQUFAAOCAQEAHmrzbfSOqSL+cAhlLqFdqzMw3Wx4+kvqrcWN7BB6
# asVYlzlrkvOR4gynKBzRXXaOiwd8E2+txDZDs8G8MVnPGDjYozvO/8pnWL/g8axh
# PqI7HrwCW0GsRGv1JvPtXqhl9splpj/K9XfrpYYqWClW+L4WEEDp0vxXLGNhN2Yl
# OSAuBwOgNgMllL18637To8LFdhZ1MJK5/3ZBNSFo0Q5eXI7DA2DmgED8wF2iVG5u
# kmengRKHoqMr27dN/+TVx+UF5tXxrvzNZhgh8z5HyeWVQmEsnSaAsg+oPQ7Jp3jf
# bnSMLEb2cuk8ZGsoVcRLZDPLeFQTOPDVcQbUPg0KNQ7gszGCAZIwggGOAgEBMHIw
# YzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExFjAUBgNV
# BAsTDU9iamVjdFNpZ24gQ0ExITAfBgNVBAMTGEdsb2JhbFNpZ24gT2JqZWN0U2ln
# biBDQQILAQAAAAABHkZAnTYwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFD0gIcEWE+juX8N8h5QJ
# JfVnmkg+MA0GCSqGSIb3DQEBAQUABIGAqYa+vQIoRaissU6w7n/pf/WAqF19PFHd
# SDYXky+SY6xVOdtZAfDh7AFWhSGJC9B/YaNYjRWuO1W687XNoLL6IMjfRj/Erg76
# 5E3eVBAny4xzuY+0t4Dz8SdNCqZKX8AcHFuUL36576gpx31TA4Ev0JifcjGa4wHT
# GJgglRdGfVk=
# SIG # End signature block
