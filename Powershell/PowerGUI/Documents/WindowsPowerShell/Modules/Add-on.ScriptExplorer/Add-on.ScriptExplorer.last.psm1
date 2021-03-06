#######################################################################################################################
# File:             Add-on.ScriptExplorer.psm1                                                                        #
# Author:           Sergey Terentyev                                                                                  #
# Publisher:        Quest Software                                                                                    #
# Copyright:        © 2013 Quest Software. All rights reserved.                                                       #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   3. Check the Add-on.ScriptExplorer module.                                                        #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this:                 #
#                       Import-Module -Name Add-on.ScriptExplorer                                                     #
#                   Please provide feedback on the PowerGUI Forums.                                                   #
#######################################################################################################################

Set-StrictMode -Version 2

#region Initialize the Script Editor Add-on.

if ($Host.Name –ne 'PowerGUIScriptEditorHost') { return }
if ($Host.Version -lt '2.1.1.1202') {
	[System.Windows.Forms.MessageBox]::Show("The ""$(Split-Path -Path $PSScriptRoot -Leaf)"" Add-on module requires version 2.1.1.1202 or later of the Script Editor. The current Script Editor version is $($Host.Version).$([System.Environment]::NewLine * 2)Please upgrade to version 2.1.1.1202 and try again.","Version 2.1.1.1202 or later is required",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
	return
}

#endregion

#region Define the .Net Extensions

if (-not ('PowerShellTypeExtensions.ScriptExplorerPlugin' -as [System.Type])) {
	$cSharpCode = @'
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;
using System.Windows.Forms;
using ActiproSoftware.UIStudio.Dock;
using Quest.PowerGUI.Engine.Shell;
using Quest.PowerGUI.SDK;
using DocumentWindow = Quest.PowerGUI.SDK.DocumentWindow;
using ToolWindow = Quest.PowerGUI.SDK.ToolWindow;

namespace PowerShellTypeExtensions
{
    public class PSCommandProcessor
    {
        private readonly Runspace _runspace;

        public PSCommandProcessor()
        {
            var runspaceConfiguration = RunspaceConfiguration.Create();
            _runspace = RunspaceFactory.CreateRunspace(runspaceConfiguration);
            _runspace.Open();
        }

        public IEnumerable<PSObject> Execute(string command, params KeyValuePair<string, object>[] arguments)
        {
            var pipeline = _runspace.CreatePipeline();
            var myCommand = new System.Management.Automation.Runspaces.Command(command, true);
            foreach (var argument in arguments)
            {
                myCommand.Parameters.Add(new CommandParameter(argument.Key, argument.Value));
            }
            pipeline.Commands.Add(myCommand);

            return pipeline.Invoke();
        }
    }

    public class PSObjectComparer : IEqualityComparer<PSObject>
    {
        public bool Equals(PSObject x, PSObject y)
        {
            var comparer = StringComparer.CurrentCultureIgnoreCase;
            return x != null && y != null && comparer.Equals(x.GetFullName(), y.GetFullName());
        }

        public int GetHashCode(PSObject obj)
        {
            return obj.GetFullName().GetHashCode();
        }
    }
    public class PSObjectStorage
    {
        public const string ParentFieldName = "Parent";
        public const string FullNameFieldName = "FullName";
        public const string TypeFieldName = "Type";
        public const string DisplayNameFieldName = "DisplayName";
        public const string IdFieldName = "Id";
        private const string RootNodeName = "Scripts";
        private const string DummyParent = "DummyParrent";
        private const string WindowVisible = "WindowVisible";

        private const string ExportToFileCommandText = "param($nodes, $dataFilePath) Export-Clixml -InputObject $nodes -Path $dataFilePath -Force";

        #region private members

        private readonly object _syncRoot = new object();

        private readonly PSObjectComparer _psObjectComparer = new PSObjectComparer();

        private readonly Dictionary<string, HashSet<PSObject>> _psObjectMap = new Dictionary<string, HashSet<PSObject>>();
        private readonly Dictionary<string, int> _filesMap = new Dictionary<string, int>();

        private readonly string _dataFilePath;

        private readonly PSCommandProcessor _commandProcessor = new PSCommandProcessor();

        private void Add(PSObject psObject)
        {
            var parent = psObject.GetParent() ?? DummyParent;

            lock (_syncRoot)
            {
                if (!_psObjectMap.ContainsKey(parent))
                {
                    _psObjectMap[parent] = new HashSet<PSObject>(_psObjectComparer);
                }

                _psObjectMap[parent].Add(psObject);
                var fileName = psObject.GetFullName();
                if (!_filesMap.ContainsKey(fileName))
                {
                    _filesMap[fileName] = 0;
                }
                ++_filesMap[fileName];
                
            }
        }

        private PSObject CreatePSObject(string objectType, string fullName, string displayName, string parent, string id)
        {
            var psObject = new PSObject();
            psObject.Members.Add(new PSNoteProperty(FullNameFieldName, fullName));
            psObject.Members.Add(new PSNoteProperty(ParentFieldName, parent));
            psObject.Members.Add(new PSNoteProperty(TypeFieldName, objectType));
            psObject.Members.Add(new PSNoteProperty(DisplayNameFieldName, displayName));
            psObject.Members.Add(new PSNoteProperty(IdFieldName, id));

            Add(psObject);
            Export();
            return psObject;
        }

        private void ImportFromFile()
        {
            var cmdText = string.Format("Import-Clixml -Path \"{0}\"", _dataFilePath);
            var map = _commandProcessor.Execute(cmdText).First().ImmediateBaseObject as Hashtable;

            foreach (PSObject psObject in map.Values)
            {
                Add(psObject);
            }
        }

        private PSObject GetOrCreateObject(string objectType, string fullName, string displayName, string parent, string id)
        {
            var obj = this[fullName, parent];
            if (obj == null)
            {
                lock (_syncRoot)
                {
                    if (obj == null)
                    {
                        obj = CreatePSObject(objectType, fullName, displayName, parent, id);
                    }
                }
            }

            return obj;
        }

        #endregion

        #region public  members

        public bool Contains(string fullName)
        {
            lock (_syncRoot)
            {
                return _filesMap.ContainsKey(fullName);
            }
        }

        public void Export()
        {
            var map = new Hashtable();

            foreach (var psObject in _psObjectMap.Values.SelectMany(it => it))
            {
                map.Add(psObject.GetId(), psObject);
            }

            var cmdArgs = new[]
                {
                    new KeyValuePair<string, object>("nodes", map),
                    new KeyValuePair<string, object>("dataFilePath", _dataFilePath)
                };

            _commandProcessor.Execute(ExportToFileCommandText, cmdArgs);
        }

        public PSObjectStorage(string dataFilePath)
        {
            _dataFilePath = dataFilePath;
            if (File.Exists(_dataFilePath))
            {
                ImportFromFile();
            }
        }

        public HashSet<PSObject> this[string parent]
        {
            get
            {
                lock (_syncRoot)
                {
                    return _psObjectMap.ContainsKey(parent) ? _psObjectMap[parent] : null;
                }
            }
        }

        public PSObject this[string fullName, string parent]
        {
            get
            {
                lock (_syncRoot)
                {
                    var objList = this[parent];
                    return objList == null ? null : objList.FirstOrDefault(it => StringComparer.CurrentCultureIgnoreCase.Equals(it.GetFullName(), fullName));
                }
            }
        }

        public PSObject CreatePSObject(string objectType, string fullName, string displayName, string parent)
        {
            return CreatePSObject(objectType, fullName, displayName, parent, Guid.NewGuid().ToString());
        }

        public PSObject RootObject
        {
            get
            {
                return GetOrCreateObject(ObjectTypes.DirType, RootNodeName, RootNodeName, DummyParent, Guid.Empty.ToString());
            }
        }

        public bool IsWindowVisible
        {
            get
            {
                return bool.Parse(GetOrCreateObject(ObjectTypes.DirType, WindowVisible, "true", DummyParent, WindowVisible).GetDisplayName());
            }

            set
            {
                GetOrCreateObject(ObjectTypes.DirType, WindowVisible, "true", DummyParent, WindowVisible).Properties[DisplayNameFieldName].Value = value.ToString();
                Export();
            }
        }

        public void Remove(PSObject psObject)
        {
            var id = psObject.GetId();
            if (_psObjectMap.ContainsKey(id))
            {
                foreach (var item in _psObjectMap[id].Select(it => it).ToList())
                {
                    Remove(item);
                }
            }

            lock (_syncRoot)
            {
                _psObjectMap[psObject.GetParent()].Remove(psObject);
                var fileName = psObject.GetFullName();
                if (--_filesMap[fileName] == 0)
                {
                    _filesMap.Remove(psObject.GetFullName());
                }
                
                Export();
            }
        }

        #endregion
    }

    public static class DocumentWindowExtension
    {
        public static bool Empty(this DocumentWindow documentWindow)
        {
            return documentWindow.Document == null || string.IsNullOrEmpty(documentWindow.Document.Path);
        }
    }

    public static class PSObjectExtension
    {
        public static string GetNodeType(this PSObject psObject)
        {
            return psObject.GetProperty<string>(PSObjectStorage.TypeFieldName);
        }

        public static string GetFullName(this PSObject psObject)
        {
            return psObject.GetProperty<string>(PSObjectStorage.FullNameFieldName);
        }

        public static string GetDisplayName(this PSObject psObject)
        {
            return psObject.GetProperty<string>(PSObjectStorage.DisplayNameFieldName);
        }

        public static string GetParent(this PSObject psObject)
        {
            return psObject.GetProperty<string>(PSObjectStorage.ParentFieldName);
        }

        public static string GetId(this PSObject psObject)
        {
            return psObject.GetProperty<string>(PSObjectStorage.IdFieldName);
        }

        public static bool IsDirectory(this PSObject psObject)
        {
            return psObject.GetNodeType() == ObjectTypes.DirType;
        }

        public static TreeNode AsTreeNode(this PSObject psObject, TreeNode parentNode)
        {
            var node = parentNode != null ? parentNode.Nodes.Cast<TreeNode>().FirstOrDefault(it => it.Name == psObject.GetId()) : null;
            return node ?? new TreeNode(psObject.GetDisplayName())
            {
                Name = psObject.GetId(),
                Tag = psObject,
                ToolTipText = psObject.IsDirectory() ? string.Empty : psObject.GetFullName()
            };
        }
    }

    public static class TreeNodeExtension
    {
        public static PSObject AsPSObject(this TreeNode node)
        {
            return node.Tag != null ? node.Tag as PSObject : null;
        }
    }

    public class ObjectTypes
    {
        public const string FileType = "FILE";
        public const string DirType = "DIR";
    }

    public static class TreeVewExtension
    {
        public static void LoadTreeFrom(this TreeView treeView, PSObjectStorage storage)
        {
            var rootNode = storage.RootObject.AsTreeNode(null);
            ScriptEditorFactory.CurrentInstance.Invoke((Action)(() => treeView.Nodes.Add(rootNode)));
            LoadTreeFrom(rootNode, storage);
        }

        public static bool Add(this TreeView treeView, TreeNode parentNode, IEnumerable<PSObject> psObjectsList)
        {
            if (psObjectsList == null || !psObjectsList.Any())
            {
                return false;
            }

            var chieldNodes = psObjectsList.Where(it => it.GetParent() != null && it.GetParent() == parentNode.Name);

            foreach (var chieldNode in chieldNodes)
            {
                var node = chieldNode.AsTreeNode(parentNode);

                if (chieldNode.GetNodeType() == ObjectTypes.FileType)
                {
                    node.ImageIndex = 1;
                    node.SelectedImageIndex = 1;
                }


                if (!parentNode.Nodes.Contains(node))
                {
                    ScriptEditorFactory.CurrentInstance.Invoke((Action)(() =>
                    {
                        if (!treeView.Nodes[0].IsExpanded)
                        {
                            treeView.Nodes[0].Expand();
                        }

                        parentNode.Nodes.Add(node);
                        if (chieldNode.GetNodeType() == ObjectTypes.FileType && !parentNode.IsExpanded)
                        {
                            parentNode.Expand();
                        }
                    }));
                }
            }

            return true;
        }

        private static void LoadTreeFrom(TreeNode rootNode, PSObjectStorage storage)
        {
            var psObjectsList = storage[rootNode.Name];
            if (rootNode.TreeView.Add(rootNode, psObjectsList))
            {
                foreach (var psObject in psObjectsList)
                {
                    if (psObject.GetNodeType() == ObjectTypes.DirType)
                    {
                        LoadTreeFrom(psObject.AsTreeNode(rootNode), storage);
                    }
                }
            }
        }
    }

    public class TreeNodeComparer: IComparer
    {
        public int Compare(object x, object y)
        {
            var nx = x as TreeNode;
            var ny = y as TreeNode;

            var tx = nx.AsPSObject().GetNodeType();
            var ty = ny.AsPSObject().GetNodeType();

            return (tx == ty) ? string.Compare(nx.Text, ny.Text) : string.Compare(tx, ty);
        }
    }

    public class ScriptExplorerPlugin
    {
        private const string ScriptExplorerWindowName = "ScriptExplorer";
        private const string ScriptExplorerWindowTitle = "Script Explorer";
        private const string PromptNodeNameLabel = "Please enter a folder name";
        private const string SupportedFilesFilter = "PowerShell Files (*.ps1;*.psm1;*.psd1;*.ps1xml;*.psc1}|*.ps1;*.psm1;*.psd1;*.psc1;*.ps1xml|PowerShell Scripts (*.ps1)|*.ps1|PowerShell Script Modules (*.psm1)|*.psm1|PowerShell Data Files (*.psd1)|*.psd1|PowerShell Configuration Files (*.ps1xml)|*.ps1xml|PowerShell Console Files (*.psc1)|*.psc1|Snippet Files (*.snippet)|*.snippet|Text Files (*.txt;*.csv)|*.txt;*.csv|XML Files (*.xml)|*.xml|All Files (*.*)|*.*";

        private readonly ToolWindow _scriptExplorerWindow;
        private readonly ImageList _imageList;
        private readonly PSObjectStorage _psObjectStorage;
        private readonly Form _mainForm;
        private readonly HashSet<string> _currentWorkSet = new HashSet<string>();


        public TreeView TreeView { get { return _scriptExplorerWindow.Control as TreeView; } }

        public ScriptExplorerPlugin(ImageList imageList, string dataFilePath)
        {
            var se = ScriptEditorFactory.CurrentInstance;
            _scriptExplorerWindow = se.ToolWindows[ScriptExplorerWindowName] ?? se.ToolWindows.Add(ScriptExplorerWindowName);
            _imageList = imageList;
            _psObjectStorage = new PSObjectStorage(dataFilePath);
            _mainForm = (Form)se.GetType().GetField("_seMain", BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.GetField).GetValue(se);
        }

        public bool Visible
        {
            get
            {
                return _scriptExplorerWindow.Visible;
            }

            set
            {
                _psObjectStorage.IsWindowVisible = value;
                if (value)
                {
                    _scriptExplorerWindow.Visible = value; // avoiding of a recursion
                    Activate();
                }
            }
        }

        private void InitScriptExplorerWindow()
        {
            _scriptExplorerWindow.Title = ScriptExplorerWindowTitle;
            _scriptExplorerWindow.Visible = _psObjectStorage.IsWindowVisible;
            _scriptExplorerWindow.Control = new TreeView
            {
                ImageList = _imageList,
                Sorted = true,
                ShowNodeToolTips = true
            };
        }

        private void InitTreeView()
        {
            TreeView.TreeViewNodeSorter = new TreeNodeComparer();
            TreeView.MouseDown += (sender, args) => TreeView.SelectedNode = TreeView.GetNodeAt(args.X, args.Y);
            TreeView.DoubleClick += treeView_DoubleClick;
            TreeView.KeyDown += (sender, args) =>
            {
                if (args.KeyCode == Keys.Delete)
                {
                    RemoveNode(TreeView.SelectedNode);
                }
            };

            TreeView.AfterLabelEdit += (sender, args) =>
            {
                args.CancelEdit = string.IsNullOrEmpty(args.Label);
                args.Node.EndEdit(args.CancelEdit);
                TreeView.LabelEdit = false;

                if (args.CancelEdit)
                {
                    return;
                }

                args.Node.AsPSObject().Properties[PSObjectStorage.DisplayNameFieldName].Value = args.Label;
                _psObjectStorage.Export();
            };

            TreeView.LoadTreeFrom(_psObjectStorage);
            var se = ScriptEditorFactory.CurrentInstance;

            foreach (var documentWindow in se.DocumentWindows)
            {
                AddDocument(documentWindow);
            }
        }

        public void Init()
        {
            InitScriptExplorerWindow();

            var se = ScriptEditorFactory.CurrentInstance;

            se.TabWindowClosed += OnTabWindowClosed;
            _mainForm.FormClosing += OnMainFromClosing;
            se.NewTabAdded += OnNewTabAdded;

            InitTreeView();

            CreateContextMenu();
        }

        private void OnMainFromClosing(object sender, EventArgs e)
        {
            ScriptEditorFactory.CurrentInstance.TabWindowClosed -= OnTabWindowClosed;
        }

        private void OnTabWindowClosed(object sender, EventArgs e)
        {
            var args = e as TabbedMdiWindowEventArgs;
            if (args != null && args.TabbedMdiWindow != null &&
                StringComparer.CurrentCultureIgnoreCase.Equals(args.TabbedMdiWindow.Key, ScriptExplorerWindowName))
            {
                Visible = false;
            }

        }

        public void Uninstall()
        {
            var se = ScriptEditorFactory.CurrentInstance;
            se.TabWindowClosed -= OnTabWindowClosed;
            _mainForm.FormClosing -= OnMainFromClosing;
            se.NewTabAdded -= OnNewTabAdded;
        }


        private void OnNewTabAdded(ActiproSoftware.UIStudio.Dock.DocumentWindow documentWindow)
        {

            if (documentWindow != null && !string.IsNullOrEmpty(documentWindow.FileName))
            {
                AddDocument(documentWindow.FileName);
            }
        }

        private void AddDocument(DocumentWindow documentWindow)
        {
            if (!documentWindow.Empty())
            {
                AddDocument(documentWindow.Document.Path);
            }
        }

        private void AddDocument(string path)
        {
            if (_psObjectStorage.Contains(path))
            {
                return;
            }

            var dirName = Path.GetDirectoryName(path);
            var displayDirName = Path.GetFileName(dirName);

            var comparer = StringComparer.CurrentCultureIgnoreCase;
            var parentNode = string.IsNullOrEmpty(displayDirName) ? RootNode :
                             (RootNode.Nodes.Cast<TreeNode>().FirstOrDefault(it => comparer.Equals(it.AsPSObject().GetFullName(), dirName)) ??
                              AddDirectory(dirName, displayDirName, _psObjectStorage.RootObject.GetId(), RootNode));

            AddFiles(new[] { path }, parentNode.Name, parentNode);
        }

        public void Activate()
        {
            ScriptEditorFactory.CurrentInstance.Invoke((Action)(() => TreeView.Focus()));
        }

        private void CreateContextMenu()
        {
            TreeView.ContextMenu = new ContextMenu();
            TreeView.ContextMenu.MenuItems.Add("Add file", OnAddFileContextMenuClick);
            TreeView.ContextMenu.MenuItems.Add("Add folder", OnAddFolderContextMenuClick);
            TreeView.ContextMenu.MenuItems.Add("Rename folder", OnEditFolderNameContextMenuClick);
            TreeView.ContextMenu.MenuItems.Add("Remove", OnRemoveNode);

            TreeView.ContextMenu.Popup += (sender, args) =>
            {
                var visible = TreeView.SelectedNode != null;

                foreach (MenuItem item in TreeView.ContextMenu.MenuItems)
                {
                    var isSelectedDirectory = IsSelectedDirectory;
                    bool enabled = true;

                    switch (item.Text)
                    {
                        case "Add file":
                        case "Add folder":
                        case "Rename folder": enabled = isSelectedDirectory; break;
                        case "Remove": enabled = TreeView.SelectedNode != RootNode; break;
                    }
                    ScriptEditorFactory.CurrentInstance.Invoke((Action)(() =>
                    {
                        item.Enabled = enabled;
                        item.Visible = visible;
                    }));
                }
            };
        }

        private bool IsSelectedDirectory
        {
            get
            {
                return TreeView.SelectedNode != null &&
                       TreeView.SelectedNode.AsPSObject().IsDirectory();
            }
        }

        private void OnAddFileContextMenuClick(object sender, EventArgs args)
        {
            if (!IsSelectedDirectory)
            {
                return;
            }

            var openFileDialog = new OpenFileDialog
            {
                AddExtension = true,
                CheckFileExists = true,
                CheckPathExists = true,
                Multiselect = true,
                Filter = SupportedFilesFilter,
                RestoreDirectory = true
            };

            if (openFileDialog.ShowDialog() != DialogResult.OK || !openFileDialog.FileNames.Any())
            {
                return;
            }

            AddFiles(openFileDialog.FileNames, TreeView.SelectedNode.AsPSObject().GetId(), TreeView.SelectedNode);
        }

        private void AddFiles(IEnumerable<string> files, string parent, TreeNode parentNode)
        {
            if (files == null || !files.ToArray().Any())
            {
                return;
            }

            var psObjectList = files.Select(it => _psObjectStorage[it, parent] ?? _psObjectStorage.CreatePSObject(ObjectTypes.FileType, it, Path.GetFileName(it), parent));
            ScriptEditorFactory.CurrentInstance.Invoke((Action)(() => TreeView.Add(parentNode, psObjectList)));
        }

        private TreeNode AddDirectory(string fullName, string displayName, string parent, TreeNode rootNode)
        {
            var psObject = _psObjectStorage[fullName, parent] ?? _psObjectStorage.CreatePSObject(ObjectTypes.DirType, fullName, displayName, parent);
            ScriptEditorFactory.CurrentInstance.Invoke((Action)(() =>
            {
                TreeView.Add(rootNode, new[] { psObject });
                TreeView.SelectedNode = psObject.AsTreeNode(rootNode);
            }));

            return psObject.AsTreeNode(rootNode);
        }

        private void OnRemoveNode(object sender, EventArgs args)
        {
            RemoveNode(TreeView.SelectedNode);
        }

        private TreeNode RootNode
        {
            get
            {
                return TreeView.Nodes.Count > 0 ? TreeView.Nodes[0] : null;
            }
        }

        private void RemoveNode(TreeNode node)
        {
            if (node == null || node == RootNode)
            {
                return;
            }

            _psObjectStorage.Remove(node.AsPSObject());
            var parentNode = node.Parent;
            parentNode.Nodes.Remove(node);            
        }

        private void OnEditFolderNameContextMenuClick(object sender, EventArgs args)
        {
            if (!IsSelectedDirectory)
            {
                return;
            }

            TreeView.LabelEdit = true;
            TreeView.SelectedNode.BeginEdit();
        }

        private void OnAddFolderContextMenuClick(object sender, EventArgs args)
        {
            if (!IsSelectedDirectory)
            {
                return;
            }

            AddDirectory(DateTime.Now.Ticks.ToString(), PromptNodeNameLabel, TreeView.SelectedNode.AsPSObject().GetId(), TreeView.SelectedNode);
            TreeView.LabelEdit = true;
            TreeView.SelectedNode.BeginEdit();
        }

        private void treeView_DoubleClick(object sender, EventArgs args)
        {
            var mouseEventArgs = args as MouseEventArgs;
            if (mouseEventArgs == null || mouseEventArgs.Button != MouseButtons.Left || IsSelectedDirectory)
            {
                return;
            }

            var node = TreeView.SelectedNode.AsPSObject();

            ScriptEditorFactory.CurrentInstance.Invoke((Action)(() =>
            {
                var path = node.GetFullName();
                DocumentWindow docWindow = null;

                foreach (var curWindow in ScriptEditorFactory.CurrentInstance.DocumentWindows)
                {
                    if (curWindow.Document == null)
                    {
                        continue;
                    }

                    if (StringComparer.InvariantCultureIgnoreCase.Equals(curWindow.Document.Path, path))
                    {
                        docWindow = curWindow;
                        break;
                    }
                }

                if (docWindow == null)
                {
                    docWindow = ScriptEditorFactory.CurrentInstance.DocumentWindows.Add(path);
                }
                docWindow.Activate();
            }));
        }
    }
}
'@	

	$refs = @(	"System.Windows.Forms",
			"System.Core",			
			"$PGHome\SDK.dll", 
			"$PGHome\ScriptEditor.Shared.dll",			
			"$PGHome\Engine.Shell.dll",			
			"$PGHome\ActiproSoftware.UIStudio.Dock.Net20.dll",
			"$PGHome\ActiproSoftware.WinUICore.Net20.dll",
			"$PGHome\ActiproSoftware.Shared.Net20.dll",
			"$PGHome\ActiproSoftware.SyntaxEditor.Net20.dll")			

Add-Type -ReferencedAssemblies $refs -IgnoreWarnings -TypeDefinition $cSharpCode | Out-Null	
}

#endregion

#region Load resources from disk.

$SeImageList = New-Object -TypeName System.Windows.Forms.ImageList
$SeFolderIcon = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\folder.ico",16,16
$SeScriptIcon = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\scripteditor_2.ico",16,16

$SeImageList.Images.Add($SeFolderIcon.ToBitmap())
$SeImageList.Images.Add($SeScriptIcon.ToBitmap())
$SeIcon = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\scriptexplorer.ico",16,16

#endregion

#region Init Script explorer window

$dataFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'ScriptEditor.Data'
$ScriptExplorerPlugin = New-Object -TypeName  'PowerShellTypeExtensions.ScriptExplorerPlugin' -ArgumentList ($SeImageList, $dataFilePath)
$ScriptExplorerPlugin.Init()

#endregion

#region update menu.

if (-not ($scriptExplorerCmdItem = $pgse.Commands['GoCommand.ScriptExplorer'])) {
	$scriptExplorerCmdItem = New-Object -TypeName Quest.PowerGUI.SDK.ItemCommand -ArgumentList 'GoCommand', 'ScriptExplorer'
	$scriptExplorerCmdItem.Text = 'Script Explorer'
	$scriptExplorerCmdItem.Image = $SeIcon.ToBitmap()
	if ($goMenu = $pgse.Menus['MenuBar.Go']) {
		$index = $goMenu.Items.Count + 1
		if ($index -lt 10) {
			$scriptExplorerCmdItem.AddShortcut("Ctrl+${index}")
		}
	}
	$scriptExplorerCmdItem.ScriptBlock = {		
		if ($PGScriptExplorer = $pgse.ToolWindows['ScriptExplorer']) {
			$ScriptExplorerPlugin.Visible = $true			
		}
	}

	$pgse.Commands.Add($scriptExplorerCmdItem)

	if ($goMenu = $pgse.Menus['MenuBar.Go']) {
		$goMenu.Items.Add($scriptExplorerCmdItem)
	}
}

#endregion

	
#region Clean-up the Add-on when it is removed.

$ExecutionContext.SessionState.Module.OnRemove = {
	$ScriptExplorerPlugin.Uninstall()
	$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

	if (($goMenu = $pgse.Menus['MenuBar.Go']) -and
	    ($scriptExplorerCmdItem = $goMenu.Items['GoCommand.ScriptExplorer'])) {
		$goMenu.Items.Remove($scriptExplorerCmdItem) | Out-Null
	}

	if ($scriptExplorerCmdItem = $pgse.Commands['GoCommand.ScriptExplorer']) {
		$pgse.Commands.Remove($scriptExplorerCmdItem) | Out-Null
	}

	if ($PGScriptExplorer = $pgse.ToolWindows['ScriptExplorer']) {
		$pgse.ToolWindows.Remove($PGScriptExplorer) | Out-Null
	}

}

#endregion


# SIG # Begin signature block
# MIIZCAYJKoZIhvcNAQcCoIIY+TCCGPUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKjlCya54TXRHACRY/cn/fnhq
# 3++gghP4MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFDMKa21/rGQ9Z9ZdrWnBSVn4Ph62MA0GCSqG
# SIb3DQEBAQUABIIBADh8ur1+G2cVxDrerCFaXDVkb7gt+JIb+q3tcphV6g2ttH3o
# dX8ftmuzea55t3A8ZAIdAY2nPPj1JhamHN+eng51Qu0b00EOqC+QosEfkyWxxZlL
# SaPPD3KlZ6EcFLyr1iBM5couvxAxemOsJifvn6eQkqlP5S9pxgc5hPvKLYPo+F4o
# kM/fx4cVvhZNtG+bb5s3OzeDD6q4/ywcRoWRG64fX8QN7Zwvky5lLwYWywxKGk5T
# MfigZ0G3qCBQEjOxmOWi9R7s5kFIOhur5XFpvwWBfgHly+8euLlKTXbGFu2B1ZCL
# vi+BNwAbFbjV1mo41aqY0f/t/1IsAmu7nze+Tc+hggILMIICBwYJKoZIhvcNAQkG
# MYIB+DCCAfQCAQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMg
# Q29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2Vy
# dmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJ
# KoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTMxMDI0MTQy
# NDAzWjAjBgkqhkiG9w0BCQQxFgQU6av3AVIw9zOjBL/eFZiFCWP1OMUwDQYJKoZI
# hvcNAQEBBQAEggEAfIlvJiEjEYk8Hw2N6ANwpirHpzDRwp7QGndAIOQ0Mu9UrqCU
# /oDEInHb/Rfyf3YX4tGvOqNvd6I3pKvnPeiYmCl9ejwm6zn1/QxGxBRUiMsl3Wua
# /fRsfFSOqnioioEV/ILaiZJ3gCj52nZ0mOIMDRIl/1GQFtvw55MNgCvVlhTfRw7W
# wnbZk42wM5109+H0mVIqHY2KtMwuHPqQs5+a1GO2a+o39FwmXLuozfYEPCle04vT
# Nw5vqVJz4Y48T68bvMhSC/reXdgql00CFL/c/5+9nGlPRCWJ0o0E/PM0HE/CHYQo
# 9LNIKO9Yxtddk6QRBxn1FL/LbVfD3oYu3XGtlA==
# SIG # End signature block
