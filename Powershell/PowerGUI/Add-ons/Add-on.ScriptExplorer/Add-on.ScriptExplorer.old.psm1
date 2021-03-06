#######################################################################################################################
# File:             Add-on.ScriptExplorer.psm1                                                                        #
# Author:           Adam Driscoll                                                                                     #
# Publisher:        Quest Software                                                                                    #
# Copyright:        © 2010 Quest Software. All rights reserved.                                                       #
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

$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

#endregion

#region Load resources from disk.

$SeImageList = New-Object -TypeName System.Windows.Forms.ImageList
$SeFolderIcon = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\folder.ico",16,16
$SeScriptIcon = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\scripteditor_2.ico",16,16

$SeImageList.Images.Add($SeFolderIcon.ToBitmap())
$SeImageList.Images.Add($SeScriptIcon.ToBitmap())
$SeIcon = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\scriptexplorer.ico",16,16

#endregion

#region Define Functions to Create Tree Nodes

function createNode([string]$nodeType, [string]$fullName, [string]$displayName, [string]$parent)
{
	$properties = @{"FullName"=$fullName;"Parent"=$parent;"Type"=$nodeType;"Id"=[Guid]::NewGuid().ToString();"DisplayName"=$displayName}
	New-Object PSObject -Property $properties
}

function constructTree([System.Windows.Forms.TreeNode]$rootNode, $nodeList, [System.Windows.Forms.TreeView]$treeView)
{
	if (-not $nodeList)
	{
		return
	}

	# KirkEdit: Replaced "where" with "Where-Object" - more friendly to newbies
	$childNodes = $nodeList | Where-Object { $_.Parent -eq $rootNode.Name }

	if ($childNodes -eq $null) {
		return
	}

	$childNodes | ForEach-Object {
		$treeNode = New-Object -TypeName System.Windows.Forms.TreeNode -ArgumentList $_.DisplayName
		$treeNode.Name = $_.Id
		$treeView.Invoke([EventHandler] {
			$rootNode.Nodes.Add($treeNode)
			# KirkEdit: Added auto-expansion of containers when you add nodes to them
			$rootNode.Expand()
		})

		if ($_.Type -eq "FILE") {
			$treeNode.ImageIndex = 1
			$treeNode.SelectedImageIndex = 1
		}

		if ($_.Type -eq "DIR") {
			constructTree $treeNode $nodeList $treeView
		}
	}
}

# KirkEdit: Calling Export-ModuleMember with no parameters to ensure that internal functions stay internal
Export-ModuleMember

#endregion

# KirkEdit: Removed in favor of more PowerShell-friendly input (even if the UI it produces isn't the greatest - I need to fix that)
#[Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")

# KirkEdit: Testing the path the PowerShell way (no need for IO.Path in PowerShell)
$dataFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'ScriptEditor.Data'
if (Test-Path $dataFilePath) {
	$nodes = Import-Clixml -Path $dataFilePath
} else {
	$nodes = $null
}

if (-not ($PGScriptExplorer = $pgse.ToolWindows['ScriptExplorer'])) {
	$PGScriptExplorer = $pgse.ToolWindows.Add('ScriptExplorer')
}

	#region Create Tree

	$PGScriptExplorer.Title = 'Script Explorer'

	$SETree = New-Object -TypeName System.Windows.Forms.TreeView

	$PGScriptExplorer.Visible = $true
	$PGScriptExplorer.Control = $SETree
	$PGScriptExplorer.Control.Invoke([EventHandler]{$PGScriptExplorer.Control.Parent.Activate($true)})
	$SETree.ImageList = $SeImageList
	$SETree.Sorted = $true
	$SETree.ContextMenu =  New-Object -TypeName System.Windows.Forms.ContextMenu
	# KirkEdit: Updated context menu text
	$SETree.ContextMenu.MenuItems.Add((New-Object -TypeName System.Windows.Forms.MenuItem -ArgumentList 'Add file...'))
	# KirkEdit: Updated context menu text
	$SETree.ContextMenu.MenuItems.Add((New-Object -TypeName System.Windows.Forms.MenuItem -ArgumentList 'Add folder...'))
	# KirkEdit: Updated context menu text
	$SETree.ContextMenu.MenuItems.Add((New-Object -TypeName System.Windows.Forms.MenuItem -ArgumentList 'Remove'))

	$SETree.add_MouseDown([System.Windows.Forms.MouseEventHandler] {
		param($sender, $e)
		
		$SETree.SelectedNode = $SETree.GetNodeAt($e.X, $e.Y)
	})

	$SETree.add_NodeMouseDoubleClick( [System.Windows.Forms.TreeNodeMouseClickEventHandler] { param($sender, $e)
		try {
			if ($e.Button -ne [System.Windows.Forms.MouseButtons]::Left) {
				return
			}

			$senode = $nodes.Get_Item($e.Node.Name)

			if ($senode.Type -eq 'DIR') {
				return
			}

			$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
			# KirkEdit: Added support for activation of documents already open in the editor
			$documentOpen = $false
			foreach ($item in $pgse.DocumentWindows) {
				if (-not ($item | Get-Member -Name Document -ErrorAction SilentlyContinue)) {
					continue
				}
				if ($item.Document.Path -eq $senode.FullName) {
					$documentOpen = $true
					$item.Activate()
					break
				}
			}
			if (-not $documentOpen) {
				# KirkEdit: Wrapped in try-catch (this can and does throw an inexplicable exception that can be ignored)
				try {
					$pgse.DocumentWindows.Add($senode.FullName) | Out-Null
				} catch {
				}
			}
		} catch {
			Write-Host "An internal error occured"
		}
	})

	if (-not $nodes) {
		$rootNode = (CreateNode "DIR" "Scripts" "Scripts" ([Guid]::Empty.ToString()))
		$rootNode.Id = ([Guid]::Empty.ToString())
		$rootNode.Parent = $null
		$nodes = @{$rootNode.Id=$rootNode}
		# KirkEdit: Added pipe to Out-Null to catch node that we don't want going anywhere
		$SETree.Invoke([EventHandler] {$SETree.Nodes.Add($rootNode.Id, $rootNode.DisplayName) | Out-Null})
	} else {
		# KirkEdit: Replaced "where" with "Where-Object" - more friendly to newbies
		$rootNode = $nodes.GetEnumerator() | Where-Object { $_.Key -eq ([Guid]::Empty.ToString()) } | ForEach-Object { $_.Value }

		# KirkEdit: Replaced "where" with "Where-Object" - more friendly to newbies
		$nonRootNodes = $nodes.GetEnumerator() | Where-Object { $_.Key -ne ([Guid]::Empty.ToString()) } | ForEach-Object { $_.Value }
		# KirkEdit: Added pipe to Out-Null to catch node that we don't want going anywhere
		$SETree.Invoke([EventHandler] {$SETree.Nodes.Add($rootNode.Id, $rootNode.DisplayName) | Out-Null})

		constructTree $SETree.Nodes[0] $nonRootNodes $SETree
	}

	#endregion

	#region Add New File Handler
	$SETree.ContextMenu.MenuItems[0].add_Click( [EventHandler] {
		try {
			$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
			$tree = $pgse.ToolWindows['ScriptExplorer'].Control	

			if ($tree.SelectedNode -eq $null) {
				return
			}

			if ($nodes.Get_Item($tree.SelectedNode.Name).Type -eq 'FILE') {
				return
			}

			$openFileDialog = New-Object -TypeName System.Windows.Forms.OpenFileDialog
			# KirkEdit: Automatically add the appropriate extension when possible
			$openFileDialog.AddExtension = $true
			# KirkEdit: Check to make sure the file exists
			$openFileDialog.CheckFileExists = $true
			# KirkEdit: Check to make sure the path exists
			$openFileDialog.CheckPathExists = $true
			# KirkEdit: Allow for multi-select!
			$openFileDialog.Multiselect = $true
			# KirkEdit: A much improved filter
			$openFileDialog.Filter = 'PowerShell Files (*.ps1;*.psm1;*.psd1;*.ps1xml;*.psc1}|*.ps1;*.psm1;*.psd1;*.psc1;*.ps1xml|PowerShell Scripts (*.ps1)|*.ps1|PowerShell Script Modules (*.psm1)|*.psm1|PowerShell Data Files (*.psd1)|*.psd1|PowerShell Configuration Files (*.ps1xml)|*.ps1xml|PowerShell Console Files (*.psc1)|*.psc1|Snippet Files (*.snippet)|*.snippet|Text Files (*.txt;*.csv)|*.txt;*.csv|XML Files (*.xml)|*.xml|All Files (*.*)|*.*'
			# KirkEdit: Cool, I like that flag: stealing it for my own Add-on
			$openFileDialog.RestoreDirectory = $true
			# KirkEdit: Add a PowerGUI section (trying to make this available in multiple locations)
			if ($openFileDialog | Get-Member -Name CustomPlaces -MemberType Property -ErrorAction SilentlyContinue) {
				$foldersToAdd = New-Object -TypeName System.Collections.Stack
				if (($windowsPowerShellFolder = Join-Path -Path ([System.Environment]::GetFolderPath('MyDocuments')) -ChildPath 'WindowsPowerShell') | Test-Path) {
					$foldersToAdd.Push($windowsPowerShellFolder)
					if (($modulesFolder = Join-Path -Path ([System.Environment]::GetFolderPath('MyDocuments')) -ChildPath 'WindowsPowerShell\Modules') | Test-Path) {
						$foldersToAdd.Push($modulesFolder)
					}
					if (($snippetsFolder = Join-Path -Path ([System.Environment]::GetFolderPath('MyDocuments')) -ChildPath 'WindowsPowerShell\Snippets') | Test-Path) {
						$foldersToAdd.Push($snippetsFolder)
					}
				}
				while ($foldersToAdd.Count -gt 0) {
					$openFileDialog.CustomPlaces.Add([string]$foldersToAdd.Pop())
				}
			}
			if ($openFileDialog.ShowDialog() -eq  [System.Windows.Forms.DialogResult]::OK) {
				# KirkEdit: Multi-select support
				for ($index = 0; $index -lt $openFileDialog.FileNames.Count; $index++) {
					$senode = CreateNode "FILE" $openFileDialog.FileNames[$index] $openFileDialog.SafeFileNames[$index] $tree.SelectedNode.Name

					$treeNode = New-Object -TypeName System.Windows.Forms.TreeNode -ArgumentList $senode.DisplayName
					$treeNode.Name = $senode.Id
					$treeNode.ImageIndex = 1
					$treeNode.SelectedImageIndex = 1

					$tree.SelectedNode.Nodes.Add($treeNode)
					# KirkEdit: Added auto-expansion of containers when you add nodes to them
					$tree.SelectedNode.Expand()
					$nodes.Add($senode.Id, $senode)
				}
				# KirkEdit: Using the dataFilePath variable that is visible throughout the module
				Export-Clixml -InputObject $nodes -Path $dataFilePath -Force
			}
		} catch {
			Write-Host "An internal error occured"
		}
	})

	#endregion

	#region Add New Folder Handler
	$SETree.ContextMenu.MenuItems[1].add_Click( [EventHandler] {
		try {
			$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
			$tree = $pgse.ToolWindows['ScriptExplorer'].Control	
			if ($nodes.Get_Item($tree.SelectedNode.Name).Type -eq 'FILE') {
				return
			}

			# KirkEdit: Converted to more PowerShell friendly input, wrapped in try-catch to avoid exception on cancel
			try {
				$dirName = Read-Host -Prompt 'Please enter a folder name'
			} catch {
			}

			# KirkEdit: Cleaned up this test (-not <string> tests for null or empty)
			if (-not $dirName) {
				# KirkEdit: Redundant error message commented out.
				# [System.Windows.Forms.MessageBox]::Show('Please enter a folder name.')
				return
			}

			if ($tree.SelectedNode.Nodes.Contains($dirName)) {
				# KirkEdit: Redundant error message commented out.
				# [System.Windows.Forms.MessageBox]::Show('Folder already exists.')
				return
			}

			$senode = CreateNode "DIR" $dirName $dirName $tree.SelectedNode.Name

			$tree.SelectedNode.Nodes.Add($senode.Id, $dirName)
			# KirkEdit: Added auto-expansion of containers when you add nodes to them
			$tree.SelectedNode.Expand()
			$nodes.Add($senode.Id, $senode)

			# KirkEdit: Using the dataFilePath variable that is visible throughout the module
			Export-Clixml -InputObject $nodes -Path $dataFilePath -Force
		} catch {
			Write-Host "An internal error occured"
		}
	})
	#endregion

	#region Remove Stuff Handler
	$SETree.ContextMenu.MenuItems[2].add_Click( [EventHandler] {
		try {
			$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
			$tree = $pgse.ToolWindows['ScriptExplorer'].Control	

			if ($tree.SelectedNode -eq $tree.Nodes[0]) {
				[System.Windows.Forms.MessageBox]::Show('Cannot remove root node.')
				return
			}

			if ($tree.SelectedNode.Nodes.Count -gt 0) {
				# KirkEdit: You should support this, with a warning/verification message box
				[System.Windows.Forms.MessageBox]::Show('Cannot remove node with children')
				return
			}

			$node = $tree.SelectedNode
			$tree.Nodes.Remove($node)
			$nodes.Remove($node.Name)
			# KirkEdit: Using the dataFilePath variable that is visible throughout the module
			Export-Clixml -InputObject $nodes -Path $dataFilePath -Force
		} catch {
			Write-Host "An internal error occured"
		}
	})
	#endregion


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
		$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
		if ($PGScriptExplorer = $pgse.ToolWindows['ScriptExplorer']) {
			$PGScriptExplorer.Visible = $true
			$PGScriptExplorer.Control.Invoke([EventHandler]{$PGScriptExplorer.Control.Parent.Activate($true)})
		}
	}

	$pgse.Commands.Add($scriptExplorerCmdItem)

	if ($goMenu = $pgse.Menus['MenuBar.Go']) {
		$goMenu.Items.Add($scriptExplorerCmdItem)
	}
}

#region Clean-up the Add-on when it is removed.

$ExecutionContext.SessionState.Module.OnRemove = {
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
# MIId3wYJKoZIhvcNAQcCoIId0DCCHcwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgh74C5R+7bfgZ8cv5cSvOY9d
# UK6gghjPMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# KoZIhvcNAQkEMRYEFHsym47E9WYbTjuT5qcf8bD3z9AsMA0GCSqGSIb3DQEBAQUA
# BIIBAKIJdgtVuo3gvaw18I0cJ8i5HTqPQJcCJTkOYSyvqbAQAuwCmWf3lwKNSadF
# +OxWhNr5l/7irn4zDEfPYrYwUknLfVsELVyARdF4jfTA3yX+c9F5isq0TGWAvMGd
# T/JGMffzTtkX+J8rW3MoxDTqZYgoGA4Yn6qaCGG7COP+da35bUqJuf7TRAOu18gR
# q5hz4t0tkq7UYxFJ2wFjt9XQoptOQL0L9ZI1d4TIcWrtX0aqOdoIrKmyCnkmHVeX
# g7D0OkUvKaVltZo0jsve3DAjkcQW2yOHgvw3sFfcYWbq0EwHKD8qSDaCy4NpDaIU
# lMvlP3P30JSbJt3MNlgpQ1UnNS6hggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQC
# AQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRp
# b24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0Eg
# LSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkD
# MQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTMwNjIxMTIwNTAxWjAjBgkq
# hkiG9w0BCQQxFgQUySLy/ugOcZep5z7YQn6UKmfkt/0wDQYJKoZIhvcNAQEBBQAE
# ggEAEq4IaWJPgVypKhwVfAaIMXVL1l8urlP77gZdAHgiHviCT/2pt9FTVql58IJq
# ucOxv7+ct3iue9l9iQIT8LHCOVVJEQp6P4FLmjdSt/3+rTQsj/xfMmjV34c8n2mW
# 6pkm6Qjz1CDO7mCjEfXqakAlZQ7bWwRa+neeYwsO3EDlcKMe82+zrCue7VA+TZD0
# Lz1MQQNTlepLVgyrXHWdT3LlB7ooFFDMVeFqDDiktS1mcernGtsvaOz0PilOHiWB
# N1WCj4CFp7ipPwaqUH8IpzH7RGr9IIDu0fgPywzaz/NeS9YgKdH/PUCEPInJWBDP
# 8OQqVAbEplG75+ZQ/asP39NkdQ==
# SIG # End signature block
