#######################################################################################################################
# File:             Add-on.ScriptEditorEssentials.psm1                                                                #
# Author:           Sergey Terentyev                                                                                  #
# Publisher:        Quest Software, Inc.                                                                              #
# Copyright:        © 2013 Quest Software, Inc. All rights reserved.                                                  #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   3. Check the Add-on.ScriptEditorEssentials module.                                                #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this:                 #
#                       Import-Module -Name Add-on.ScriptEditorEssentials                                             #
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

if (-not ('ScriptEditorEssentialsTypeExtensions.ScriptEditorEssentialsPlugin' -as [System.Type])) {
	$cSharpCode = @'
using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using ActiproSoftware.SyntaxEditor;
using ActiproSoftware.UIStudio.TabStrip;
using Quest.PowerGUI.SDK;

namespace ScriptEditorEssentialsTypeExtensions
{
    public class SettingsStorage
    {
        private const string ExportToFileCommandText = "param($objects, $dataFilePath) Export-Clixml -InputObject $objects -Path $dataFilePath -Force";
        private const string ImportToFileCommandTextFormat = "Import-Clixml -Path \"{0}\"";

        public event EventHandler SettingsChanged;

        public Encoding CurrentEncoding
        {
            get
            {
                var value = this["Default", "Encoding"];
                return value is Encoding ? value as Encoding : Encoding.GetEncoding((int)((value as PSObject).Properties["CodePage"].Value));
            }
            set { this["Default", "Encoding"] = value; }
        }

        public bool ViewWhitespace
        {
            get { return (bool)this["Current", "ViewWhitespace"]; }
            set { this["Current", "ViewWhitespace"] = value; }
        }

        public bool WordWrap
        {
            get { return (bool)this["Current", "WordWrap"]; }
            set { this["Current", "WordWrap"] = value; }
        }

        public bool VirtualWhitespace
        {
            get { return (bool)this["Current", "VirtualWhitespace"]; }
            set { this["Current", "VirtualWhitespace"] = value; }
        }

        public bool TabStripScrolling
        {
            get { return (bool)this["Current", "TabStripScrolling"]; }
            set { this["Current", "TabStripScrolling"] = value; }
        }

        public Font Font
        {
            get
            {
                if (_font == null)
                {
                    var curWin = ScriptEditorFactory.CurrentInstance.CurrentDocumentWindow;
                    if (curWin != null && curWin.Document != null)
                    {
                        _font = curWin.Document.Font;
                    }
                }

                return _font;
            }
            set
            {
                _font = value;
                InvokeOnSettingsChanged();
            }
        }

        public SettingsStorage(string configPath)
        {
            _configPath = configPath;
            var runspaceConfiguration = System.Management.Automation.Runspaces.RunspaceConfiguration.Create();
            _runspace = System.Management.Automation.Runspaces.RunspaceFactory.CreateRunspace(runspaceConfiguration);
            _runspace.Open();

            if (File.Exists(_configPath))
            {
                ImportSettings();
            }
            else
            {
                CreateDefaultSettings();
            }
        }

        private readonly System.Management.Automation.Runspaces.Runspace _runspace;

        private readonly string _configPath;

        private Hashtable _settings;

        private Font _font = null;

        private object this[object key, string propertyName]
        {
            get
            {
                var h = (_settings[key] is PSObject ? ((PSObject)_settings[key]).ImmediateBaseObject : _settings[key]) as Hashtable;
                return h == null ? null : h[propertyName];
            }
            set
            {
                var h = (_settings[key] is PSObject ? ((PSObject)_settings[key]).ImmediateBaseObject : _settings[key]) as Hashtable;
                if (h == null)
                {
                    return;
                }
                h[propertyName] = value;
                ExportSettings();
                InvokeOnSettingsChanged();
            }
        }

        private void InvokeOnSettingsChanged()
        {
            if (SettingsChanged != null)
            {
                SettingsChanged(this, EventArgs.Empty);
            }
        }

        private IEnumerable<PSObject> ExecutePSCommand(string command, params KeyValuePair<string, object>[] arguments)
        {
            var pipeline = _runspace.CreatePipeline();
            var myCommand = new System.Management.Automation.Runspaces.Command(command, true);
            foreach (var argument in arguments)
            {
                myCommand.Parameters.Add(new System.Management.Automation.Runspaces.CommandParameter(argument.Key, argument.Value));
            }
            pipeline.Commands.Add(myCommand);

            return pipeline.Invoke();
        }

        private void ImportSettings()
        {
            var cmdText = string.Format(ImportToFileCommandTextFormat, _configPath);
            _settings = ExecutePSCommand(cmdText).First().ImmediateBaseObject as Hashtable;
        }

        private void ExportSettings()
        {
            var cmdArgs = new[]
                {
                    new KeyValuePair<string, object>("objects", _settings),
                    new KeyValuePair<string, object>("dataFilePath", _configPath)
                };

            ExecutePSCommand(ExportToFileCommandText, cmdArgs);
        }

        private void CreateDefaultSettings()
        {
            var currentObj = new Hashtable
                {
                   { "WordWrap", false },
                   { "ViewWhitespace", false },
                   { "VirtualWhitespace", false },
                   { "FavoritePaths", new string[0] },
                   { "TabStripScrolling", true }
                };

            var defaultObj = new Hashtable
                {
                    { "Encoding", Encoding.Unicode },
                    { "WordWrapType", "Character" },
                    { "RememberSearchMatchCase", false },
                    { "RememberSearchMatchWholeWord", false },
                    { "RememberSearchUp", false },
                    { "RememberSearchExpandedTextOnly", false },
                    { "EnableSmartSelectionSearch", false }
                };

            _settings = new Hashtable { { "Default", defaultObj }, { "Current", currentObj } };
        }
    }

    public class ScriptEditorEssentialsPlugin
    {
        private readonly Dictionary<string, Encoding> _encodings = new Dictionary<string, Encoding>();

        private readonly SettingsStorage _settingsStorage;
        private readonly Hashtable _imageLibrary;

        public ScriptEditorEssentialsPlugin(string configPath, Hashtable imageLibrary)
        {
            _settingsStorage = new SettingsStorage(configPath);
            _imageLibrary = imageLibrary;
        }

        public void Init()
        {
            _encodings.Add("ASCII", Encoding.ASCII);
            _encodings.Add("UTF8", Encoding.UTF8);
            _encodings.Add("Unicode", Encoding.Unicode);
            _encodings.Add("UnicodeBigEndian", Encoding.BigEndianUnicode);
            _encodings.Add("UTF32", Encoding.UTF32);
            _encodings.Add("UTF32BigEndian", Encoding.GetEncoding("UTF-32BE"));
            CreateMenu();

            var editor = ScriptEditorFactory.CurrentInstance;
            editor.CurrentDocumentWindowChanged += OnChanging;
            _settingsStorage.SettingsChanged += OnChanging;

            var processArchitecture = Process.GetCurrentProcess().MainModule.FileName.IndexOf("ScriptEditor_x86.exe") >= 0 ?
                                      "32-bit" : "64-bit";

            UpdateStatusStripLabel("ProcessArchitecture", processArchitecture);
            UpdateStatusStripLabel("ApartmentState", Thread.CurrentThread.GetApartmentState().ToString());
            UpdateStatusStripLabel("Encoding");
            OnChanging(this, EventArgs.Empty);
        }

        public void Remove()
        {
            var editor = ScriptEditorFactory.CurrentInstance;

            editor.CurrentDocumentWindowChanged -= OnChanging;
            _settingsStorage.SettingsChanged -= OnChanging;

            foreach (var key in _encodings.Keys)
            {
                RemoveCommand(string.Format("FileCommand.{0}", key));
            }

            RemoveCommand("ViewCommand.TabScrollButtons");
            RemoveCommand("ViewCommand.ZoomIn");
            RemoveCommand("ViewCommand.ZoomOut");
            RemoveCommand("EditCommand.ViewWhitespace");
            RemoveCommand("EditCommand.WordWrap");
            RemoveCommand("EditCommand.VirtualWhitespace");

            var fileMenu = editor.Menus["MenuBar.File"] as BarMenu;
            if (fileMenu != null)
            {
                RemoveMenu(fileMenu.Items, "FileCommand.Encoding");
            }

            var viewMenu = editor.Menus["MenuBar.View"] as BarMenu;
            if (viewMenu != null)
            {
                RemoveMenu(viewMenu.Items, "ViewCommand.ZoomIn");
                RemoveMenu(viewMenu.Items, "ViewCommand.ZoomOut");
                RemoveMenu(viewMenu.Items, "ViewCommand.TabScrollButtons");
            }

            var editMenu = editor.Menus["MenuBar.Edit"] as BarMenu;
            if (editMenu != null)
            {
                var advancedMenu = editMenu.Items["EditCommand.Advanced"] as BarMenu;
                if (advancedMenu != null)
                {
                    RemoveMenu(viewMenu.Items, "EditCommand.ViewWhitespace");
                    RemoveMenu(viewMenu.Items, "EditCommand.WordWrap");
                    RemoveMenu(viewMenu.Items, "EditCommand.VirtualWhitespace");
                }
            }

            RemoveStatusStripLabel("ProcessArchitecture");
            RemoveStatusStripLabel("ApartmentState");
            RemoveStatusStripLabel("Encoding");

            if (editor.CurrentDocumentWindow != null)
            {
                SetTextEditorSettings(editor.CurrentDocumentWindow,
                                      GetOriginalWindow(editor.CurrentDocumentWindow), false, false, false);

            }
        }

        private void RemoveMenu(BarItemList list, string fullName)
        {
            var item = list[fullName];
            if (item != null)
            {
                list.Remove(item);
            }

            RemoveCommand(fullName);
        }

        private void RemoveCommand(string fullName)
        {
            var editor = ScriptEditorFactory.CurrentInstance;
            var cmd = editor.Commands[fullName];
            if (cmd != null)
            {
                editor.Commands.Remove(cmd);
            }
        }

        private void Invoke(MethodInvoker method)
        {
            ScriptEditorFactory.CurrentInstance.Invoke(method);
        }

        private void RemoveStatusStripLabel(string name)
        {
            var statusBar = ScriptEditorFactory.CurrentInstance.ToolWindows["PowerShellConsole"].Control.TopLevelControl.Controls["statusStrip1"] as StatusStrip;
            var l = statusBar.Items[name];
            if (l != null)
            {
                Invoke(() => statusBar.Items.Remove(l));
            }
        }

        private void UpdateStatusStripLabel(string name, string text = "")
        {
            var statusBar = ScriptEditorFactory.CurrentInstance.ToolWindows["PowerShellConsole"].Control.TopLevelControl.Controls["statusStrip1"] as StatusStrip;
            var l = statusBar.Items[name];
            if (l == null)
            {
                l = new ToolStripStatusLabel(text)
                    {
                        Name = name,
                        TextAlign = ContentAlignment.MiddleRight,
                        DisplayStyle = ToolStripItemDisplayStyle.Text,
                        BorderStyle = Border3DStyle.Etched,
                        BorderSides = ToolStripStatusLabelBorderSides.Left,
                        Anchor = AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Top | AnchorStyles.Bottom
                    };
                Invoke(() => statusBar.Items.Insert(statusBar.Items.Count - 1, l));
            }

            l.Text = text;
            l.Visible = !string.IsNullOrEmpty(text);
        }

        private void SetVisibleTabStrip(object originalWindow, bool visible)
        {
            var originalWindowParent = originalWindow.GetType().GetProperty("Parent").GetValue(originalWindow, null);
            var tabStrip = (TabStrip)originalWindowParent.GetType().GetProperty("TabStrip").GetValue(originalWindowParent, null);
            Invoke(() =>
            {
                tabStrip.TabOverflowStyle = visible ? TabStripTabOverflowStyle.ScrollButtons : TabStripTabOverflowStyle.None;
            });
        }

        private object GetOriginalWindow(DocumentWindow documentWindow)
        {
            return documentWindow.GetType().GetProperty("OriginalWindow", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(documentWindow, null);
        }

        private void SetTextEditorSettings(DocumentWindow currentDocumentWindow, object originalWindow, bool viewWhitespace, bool wordWrap, bool virtualWhitespace)
        {
            currentDocumentWindow.Document.WhitespaceSpacesVisible = viewWhitespace;
            currentDocumentWindow.Document.WhitespaceTabsVisible = viewWhitespace;

            currentDocumentWindow.Document.WordWrap = wordWrap ? WordWrapType.Character : WordWrapType.None;
            currentDocumentWindow.Document.WordWrapping = wordWrap;
            currentDocumentWindow.Document.WordWrapGlyphVisible = wordWrap;

            currentDocumentWindow.Document.VirtualSpaceAtLineEndEnabled = virtualWhitespace;

            SetVisibleTabStrip(originalWindow, _settingsStorage.TabStripScrolling);
        }



        private void OnChanging(object sender, EventArgs eventArgs)
        {
            UpdateStatusStripLabel("Encoding");
            var currentDocumentWindow = ScriptEditorFactory.CurrentInstance.CurrentDocumentWindow;
            if (currentDocumentWindow == null || currentDocumentWindow.Document == null)
            {
                return;
            }

            UpdateStatusStripLabel("Encoding", _settingsStorage.CurrentEncoding.EncodingName);

            var originalWindow = GetOriginalWindow(currentDocumentWindow);

            originalWindow.GetType().GetProperty("Encoding").SetValue(originalWindow, _settingsStorage.CurrentEncoding, null);

            SetTextEditorSettings(currentDocumentWindow, originalWindow, _settingsStorage.ViewWhitespace, _settingsStorage.WordWrap, _settingsStorage.VirtualWhitespace);

            currentDocumentWindow.Document.Font = _settingsStorage.Font;
        }

        private void CreateMenu()
        {
            CreateEncodingMenu();
            CreateZoomMenu();
            CreateTabStripScrollingMenu();
            CreateEditorMenu();
        }

        private BarItem CreateMenuItem(BarMenu rootMenu, string category, string name, Func<Command> cmdInitAction,
                                       string afterFullName = null, bool firstInGroup = false)
        {
            var fullName = string.Format("{0}.{1}", category, name);

            if (rootMenu.Items[fullName] != null)
            {
                return rootMenu.Items[fullName];
            }

            var menuCommand = cmdInitAction();

            if (!string.IsNullOrEmpty(afterFullName) && rootMenu.Items[afterFullName] != null)
            {
                var index = rootMenu.Items.IndexOf(rootMenu.Items[afterFullName]);
                rootMenu.Items.Insert(++index, menuCommand);
            }
            else
            {
                rootMenu.Items.Add(menuCommand);
            }

            var menu = rootMenu.Items[menuCommand.FullName];
            menu.FirstInGroup = firstInGroup;
            return menu;
        }

        private BarMenu CreateBarMenuItem(string rootFullName, string category, string name,
                                    string text, string afterFullName = null, bool firstInGroup = false)
        {
            var rootMenu = ScriptEditorFactory.CurrentInstance.Menus[rootFullName] as BarMenu;
            if (rootMenu == null)
            {
                return null;
            }

            Func<Command> cmdInitAction = () => new MenuCommand(category, name) { Text = text };

            return CreateMenuItem(rootMenu, category, name, cmdInitAction, afterFullName, firstInGroup) as BarMenu;
        }

        private BarItem CreateSubMenuItem(BarMenu rootMenu, string category, string name, string text, Action action,
                                          string afterFullName = null, bool firstInGroup = false,
                                          bool checkable = false, bool @checked = false)
        {
            Func<Command> cmdInitAction = () =>
                {
                    var cmd = new ItemCommand(category, name)
                        {
                            Enabled = true,
                            Checkable = @checkable,
                            Checked = @checked,
                            Text = text
                        };

                    ScriptEditorFactory.CurrentInstance.Commands.Add(cmd);
                    return cmd;
                };

            var subMenu = CreateMenuItem(rootMenu, category, name, cmdInitAction, afterFullName, firstInGroup);
            ((ItemCommand)subMenu.Command).Invoking += (s, e) => action();
            return subMenu;
        }


        private void CreateEncodingSubMenu(BarMenu encodingMenu, string category, string name, bool @checked = false)
        {
            Action action = () =>
            {
                encodingMenu.Items.Select(it => it.Command).Cast<ItemCommand>().First(it => it.Checked && it.Name != name).Checked = false;
                if (ScriptEditorFactory.CurrentInstance.CurrentDocumentWindow.Document != null)
                {
                    ScriptEditorFactory.CurrentInstance.CurrentDocumentWindow.Document.Modified = true;
                }
                _settingsStorage.CurrentEncoding = _encodings[name];
            };

            var subMenu = CreateSubMenuItem(encodingMenu, category, name, _encodings[name].EncodingName, action, null, false, true, @checked);

            //for compatible with previous version of add-on
            if (name == "ASCII")
            {
                subMenu.Text = name;
            }
            else if (name == "UTF8")
            {
                subMenu.Text = "UTF-8";
            }
        }

        private void CreateEncodingMenu()
        {
            var encodingMenu = CreateBarMenuItem("MenuBar.File", "FileCommand", "Encoding", "Encodin&g", "FileCommand.SaveAll", true);
            if (encodingMenu == null)
            {
                return;
            }

            foreach (var key in _encodings.Keys)
            {
                CreateEncodingSubMenu(encodingMenu, encodingMenu.Command.Category, key, _encodings[key].CodePage == _settingsStorage.CurrentEncoding.CodePage);
            }
        }

        private void CreateZoomMenu()
        {
            var viewMenu = ScriptEditorFactory.CurrentInstance.Menus["MenuBar.View"] as BarMenu;
            if (viewMenu == null)
            {
                return;
            }

            Action<int> action = delta =>
                {
                    var curWindow = ScriptEditorFactory.CurrentInstance.CurrentDocumentWindow;

                    if (curWindow != null && curWindow.Document != null && 
                        (delta > 0 && curWindow.Document.Font.Size < 32 || delta < 0 && curWindow.Document.Font.Size > 5))
                    {

                        _settingsStorage.Font = new Font(curWindow.Document.Font.Name,
                                                         (curWindow.Document.Font.SizeInPoints + delta),
                                                         curWindow.Document.Font.Style);
                    }

                    var consoleWindow = ScriptEditorFactory.CurrentInstance.ToolWindows["PowerShellConsole"];
                    if (consoleWindow == null)
                    {
                        return;
                    }

                    Invoke(() =>
                    {
                        consoleWindow.Control.Font = _settingsStorage.Font;
                    });
                };

            Action zoomInAction = () => action(1);
            Action zoomOutAction = () => action(-1);

            var zoomInMenu = CreateSubMenuItem(viewMenu, "ViewCommand", "ZoomIn", "&Zoom In", zoomInAction, "ViewCommand.Font", true);
            zoomInMenu.Command.AddShortcut(Keys.Control | Keys.Add);
            zoomInMenu.Command.AddShortcut(Keys.Control | Keys.Oemplus);

            var zoomOut = CreateSubMenuItem(viewMenu, "ViewCommand", "ZoomOut", "&Zoom Out", zoomOutAction);
            zoomOut.Command.AddShortcut(Keys.Control | Keys.Subtract);
            zoomOut.Command.AddShortcut(Keys.Control | Keys.OemMinus);
        }

        private void CreateTabStripScrollingMenu()
        {
            var viewMenu = ScriptEditorFactory.CurrentInstance.Menus["MenuBar.View"] as BarMenu;
            if (viewMenu == null)
            {
                return;
            }

            Action action = () =>
                {
                    var @checked = (viewMenu.Items["ViewCommand.TabScrollButtons"].Command as ItemCommand).Checked;
                    _settingsStorage.TabStripScrolling = @checked;
                };

            CreateSubMenuItem(viewMenu, "ViewCommand", "TabScrollButtons", "Tab Scroll Buttons", action, "ViewCommand.LineNumbers", false, true, _settingsStorage.TabStripScrolling);
        }

        private void CreateEditorMenu()
        {
            var editMenu = ScriptEditorFactory.CurrentInstance.Menus["MenuBar.Edit"] as BarMenu;
            if (editMenu == null)
            {
                return;
            }

            var advancedMenu = editMenu.Items["EditCommand.Advanced"] as BarMenu;

            if (advancedMenu == null)
            {
                return;
            }

            Action viewWiteSpaceAction = () =>
                {
                    var @checked = (advancedMenu.Items["EditCommand.ViewWhitespace"].Command as ItemCommand).Checked;
                    _settingsStorage.ViewWhitespace = @checked;
                };

            var viewWiteSpaceMenu = CreateSubMenuItem(advancedMenu, "EditCommand", "ViewWhitespace", "View &White Space", viewWiteSpaceAction, null, true, true, _settingsStorage.ViewWhitespace);
            viewWiteSpaceMenu.Command.AddShortcut(Keys.Control | Keys.Shift | Keys.W);
            viewWiteSpaceMenu.Command.Image = (Bitmap)_imageLibrary["ViewWhitespaceImage16"];

            Action trigger = () =>
            {
                if ((advancedMenu.Items["EditCommand.WordWrap"].Command as ItemCommand).Checked && _settingsStorage.VirtualWhitespace)
                {
                    (advancedMenu.Items["EditCommand.VirtualWhitespace"].Command as ItemCommand).Checked = false;
                }
                else if ((advancedMenu.Items["EditCommand.VirtualWhitespace"].Command as ItemCommand).Checked && _settingsStorage.WordWrap)
                {
                    (advancedMenu.Items["EditCommand.WordWrap"].Command as ItemCommand).Checked = false;
                }

                _settingsStorage.WordWrap = (advancedMenu.Items["EditCommand.WordWrap"].Command as ItemCommand).Checked;
                _settingsStorage.VirtualWhitespace = (advancedMenu.Items["EditCommand.VirtualWhitespace"].Command as ItemCommand).Checked;
            };

            var wordWrapMenu = CreateSubMenuItem(advancedMenu, "EditCommand", "WordWrap", "Word W&rap", trigger, null, true, true, _settingsStorage.WordWrap);
            wordWrapMenu.Command.AddShortcut(Keys.Control | Keys.Alt | Keys.W);
            wordWrapMenu.Command.Image = (Bitmap)_imageLibrary["WordWrapImage16"];

            CreateSubMenuItem(advancedMenu, "EditCommand", "VirtualWhitespace", "&Virtual White Space", trigger, null, false, true, _settingsStorage.VirtualWhitespace);
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

#region Check the PowerShell Host.

$minimumSdkVersion = [System.Version]'1.0'

if ($Host.Name -ne 'PowerGUIScriptEditorHost') {
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
	      WordWrapIcon16 = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\WordWrap.ico",16,16
	ViewWhitespaceIcon16 = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ViewWhiteSpace.ico",16,16
	  ClearConsoleIcon16 = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ClearPowerShellConsole.ico",16,16
	  ClearConsoleIcon32 = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ClearPowerShellConsole.ico",32,32
	IncreaseIndentIcon16 = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\IncreaseIndent.ico",16,16
	DecreaseIndentIcon16 = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\DecreaseIndent.ico",16,16
}

$imageLibrary = @{
	      WordWrapImage16 = $iconLibrary['WordWrapIcon16'].ToBitmap()
	ViewWhitespaceImage16 = $iconLibrary['ViewWhitespaceIcon16'].ToBitmap()
	  ClearConsoleImage16 = $iconLibrary['ClearConsoleIcon16'].ToBitmap()
	  ClearConsoleImage32 = $iconLibrary['ClearConsoleIcon32'].ToBitmap()
	IncreaseIndentImage16 = $iconLibrary['IncreaseIndentIcon16'].ToBitmap()
	DecreaseIndentImage16 = $iconLibrary['DecreaseIndentIcon16'].ToBitmap()
}

#endregion

#region Initialize the Add-on.

#region Init .Net plugin

$configPath = "${PSScriptRoot}\Add-on.ScriptEditorEssentials.config.xml"

$ScriptEditorEssentialsPlugin = New-Object -TypeName 'ScriptEditorEssentialsTypeExtensions.ScriptEditorEssentialsPlugin' -ArgumentList ($configPath,[System.Collections.Hashtable]$imageLibrary)
$ScriptEditorEssentialsPlugin.Init()
#endregion

#region Create the ClearPowerShellConsole menu item in the View menu.

if (($viewMenu = $PGSE.Menus['MenuBar.View']) -and
    (-not ($clearConsoleMenuItem = $viewMenu.Items['ViewCommand.ClearPowerShellConsole']))) {
	if (-not ($clearConsoleCommand = $PGSE.Commands['ViewCommand.ClearPowerShellConsole'])) {
		$clearConsoleCommand = New-Object -TypeName Quest.PowerGUI.SDK.ItemCommand -ArgumentList 'ViewCommand','ClearPowerShellConsole'
		$clearConsoleCommand.Text = 'Cl&ear PowerShell Console'
		$clearConsoleCommand.Image = $imageLibrary['ClearConsoleImage16']
		$clearConsoleCommand.AddShortcut('Control+R')
		$clearConsoleCommand.ScriptBlock = {
			Clear-Host
		}
		$PGSE.Commands.Add($clearConsoleCommand)
	}
	$viewMenu.Items.Add($clearConsoleCommand)
	if ($clearConsoleMenuItem = $viewMenu.Items['ViewCommand.ClearPowerShellConsole']) {
		$clearConsoleMenuItem.FirstInGroup = $true
	}
}

#endregion

#endregion


#region Clean-up the Add-on when it is removed.

$ExecutionContext.SessionState.Module.OnRemove = {
	#region Remove the ClearPowerShellConsole menu item from the View menu.

	if (($viewMenu = $PGSE.Menus['MenuBar.View']) -and
	    ($clearPowerShellConsoleMenuItem = $viewMenu.Items['ViewCommand.ClearPowerShellConsole'])) {
		$viewMenu.Items.Remove($clearPowerShellConsoleMenuItem) | Out-Null
	}

	if ($clearPowerShellConsoleCommand = $PGSE.Commands['ViewCommand.ClearPowerShellConsole']) {
		$PGSE.Commands.Remove($clearPowerShellConsoleCommand) | Out-Null
	}

	#endregion
	
	$ScriptEditorEssentialsPlugin.Remove()
}
#endregion

# SIG # Begin signature block
# MIId3wYJKoZIhvcNAQcCoIId0DCCHcwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqyu5oaZgeFtTCK6bNxs7D2b8
# A7agghjPMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# KoZIhvcNAQkEMRYEFC7TCJ6thwXb2tuTgAVrEJy20DsvMA0GCSqGSIb3DQEBAQUA
# BIIBAM4LJmi/2X00mxIPmbu84ly+S82vBL3H47hib62LprJZsUC7dO2tDR+Fjygw
# mW2I8ghStwve/NKCXzJoM82eexM0DXBpx8SDMpuXELtSv7O3FPu4+rP35h/1Kgsu
# vVsoib8rkPjzWPtZQYCJb61cgE/esrW1BKc7RoB934bLhyQDmntuFiWrTRZqzusl
# ssTfTK0hqVqhuZHvR1H0r/HPvpxsoWLtYQyGWC5hEeviaTor7gcGtIrUgws6Yl7A
# 1ScAQ9cuH8DYsb5msXX6OOXjF5vhRh3KOGGyzfRjvbw0gjw7CsnWBN+YBauhGmKt
# xP4JAvDQpcLuNnTcQLKzkXgKTrWhggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQC
# AQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRp
# b24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0Eg
# LSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkD
# MQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTMwNjIxMTY1MTM2WjAjBgkq
# hkiG9w0BCQQxFgQUSTAKne3lLdlcpXHctHvJGw89ascwDQYJKoZIhvcNAQEBBQAE
# ggEAk0fqdaSBpGX+hiytScuPq78gG7DGHDH71CaqP46tBEGj1HWExE6UIybW/Cvz
# 4XDdSPjkpiR5Vqq+gQfq23T2LVIHPt8VfpkWYNcbtdCCXvvEYOOQPMXJ+d1vvoyC
# VG7xnwjAzoThYl5RP+0kC8oCKjHXE8Acm6B6VCvFI4cCYhBKu5aKA0vCYQytn+fe
# xO9M9Mk+1nxv+hWxPaC55LvV6Otmd0dZKWhom2VlS6Dsk+JokMbZcP+Cly3hxzR7
# JTxTn/SkmugL37T5dcQfGepDRka5zgg3BkNzZQfGg9M2wCjX0Utz/pTu44ADfE1n
# Tl6KGgmVMqb3Ujbm5Eg4/7GMAQ==
# SIG # End signature block
