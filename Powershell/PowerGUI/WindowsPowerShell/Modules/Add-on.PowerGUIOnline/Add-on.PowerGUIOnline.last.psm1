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


#region Define .NET Types
if (-not ('Addon.PowerGUIOnline.WebBrowserWindow' -as [System.Type])) {
	$cSharpCode = @'
using System;
using System.Linq;
using System.Windows.Forms;
using ActiproSoftware.UIStudio.Dock;
using Quest.PowerGUI.SDK;
using ToolWindow = Quest.PowerGUI.SDK.ToolWindow;

namespace Addon.PowerGUIOnline
{
    public class WebBrowserWindow
    {
        private const string PowerGUIOnlineKey = "PowerGUIOnline";

        private readonly ToolWindow _poshWindow;

        public WebBrowserWindow()
        {
            var editor = ScriptEditorFactory.CurrentInstance;
            _poshWindow = editor.ToolWindows[PowerGUIOnlineKey] ?? editor.ToolWindows.Add(PowerGUIOnlineKey);
            _poshWindow.Visible = true;
            _poshWindow.Title = PowerGUIOnlineKey;
            if (!(_poshWindow.Control is WebBrowser))
            {
                var webBrowser = new WebBrowser();
                webBrowser.DocumentCompleted += (sender, args) => Activate();
                _poshWindow.Control = webBrowser;
                
            }
            editor.Invoke((Action)(() =>_poshWindow.Control.Parent.GetType().GetProperty("State").SetValue(_poshWindow.Control.Parent, ToolWindowState.TabbedDocument, null)));                        
        }

        public void Navigate(string url)
        {
            if (string.IsNullOrEmpty(url))
            {
                return;
            }

            var webBrowser = _poshWindow.Control as WebBrowser;
            if (webBrowser == null)
            {
                return;
            }

            ScriptEditorFactory.CurrentInstance.Invoke((Action) (() => webBrowser.Navigate(url)));
            
        }

        public void Activate()
        {
            ScriptEditorFactory.CurrentInstance.Invoke((Action)(() =>
            {
                _poshWindow.Visible = true;
                var m = _poshWindow.Control.Parent.GetType() .GetMethods().First(it => it.Name == "Activate" && it.GetParameters().Count() == 1);
                m.Invoke(_poshWindow.Control.Parent, new object[] {true});
            }));
        }
    }
}
'@

$refs = @(	"System.Windows.Forms",
			"System.Core",
			"System.Drawing",			
			"$PGHome\SDK.dll", 
			"$PGHome\ActiproSoftware.UIStudio.Dock.Net20.dll",
			"$PGHome\ActiproSoftware.WinUICore.Net20.dll",
			"$PGHome\ActiproSoftware.Shared.Net20.dll",
			"$PGHome\ActiproSoftware.SyntaxEditor.Net20.dll")			

Add-Type -ReferencedAssemblies $refs -IgnoreWarnings -TypeDefinition $cSharpCode | Out-Null	
}
#endregion

#region Determine if the script is running in STA mode.

$staMode = ([System.Threading.Thread]::CurrentThread.ApartmentState -eq [System.Threading.ApartmentState]::STA)

#endregion

#region Create and/or initialize the web browser window when using STA mode.

if ($staMode) {
	$webBrowserWindow = New-Object -TypeName 'Addon.PowerGUIOnline.WebBrowserWindow'
	$webBrowserWindow.Navigate($powerGUIUrl[0].Value.URL)
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
		$webBrowserWindow.Activate()		
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
					$scriptBlock = "`$webBrowserWindow.Navigate('$($item.Value.URL)')"

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
# MIId3wYJKoZIhvcNAQcCoIId0DCCHcwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdqXJ1g7OQ01NzlsNFVuwvy7Q
# UdegghjPMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# KoZIhvcNAQkEMRYEFP5Rgl86aPk2DkfYFrcaDkScNWvWMA0GCSqGSIb3DQEBAQUA
# BIIBADp1rrEl06NqssJQJuOq4KJyHsglGmEaT5U8oqclbSpBTvIXZxeXV4VAvNyL
# tpX0RxFDtsP9uJAfbyDL087jSfz/9SlkOeMoNr4gptaiFcyrNrja55Ndli3jLF5g
# UyALbnckmKn9eTgZ6Pk9+GJ6QXt4HLMt6mFO3XwrkEeiQvH9wz2pDBhgMS+0Occk
# uCXiJi1T/64Fk2pLjHdRN49uZmQD7uYuM34e5VthrvH3Ey7XiwA3G3ANkuk35Lmm
# AElw746gX+WhfgwR+5aLdfvngOmr1PnzFTlbe6HRp7kJc2H2jVXH+FwEKXvsjWF1
# Qtf8ZvT9yH4ggoBc768o4iS6MoOhggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQC
# AQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRp
# b24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0Eg
# LSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkD
# MQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTMwNjI2MTUwMTQwWjAjBgkq
# hkiG9w0BCQQxFgQUUJZZgpOq3wOHv6rY5zfUsKu/7ikwDQYJKoZIhvcNAQEBBQAE
# ggEAmHJI32KW/8yURdiAzCrGXBO55s/dVefOGg54lrEpQeuhZd0BD6gYWm3kC1FT
# mPpNL3yZBWwzzfxi6OaARiuAHmSuWnN2kyZq1skVV7sx9ALPWUmIJS+NU/j/sDWL
# 50DRR6aTpygy7ZGdqqLMH3xyMu1G1YooMLuBEKSBDPdfE41xYZRqEziUXVaoyvH8
# qpJ2gqcvPvSyX24L7IXvYpCIvn7JCn2CmIwMOQrQhQpbaf7lkGP/1V6AV4G8DClV
# HIA7rnwLwdKdMxd8ZiBRCN96XWfwUAo9iGmTfzM+SrpkgUdtxzgZ3jK52LSGHnnt
# s2IBhluQVsOA9DBervVcLJyOHw==
# SIG # End signature block
