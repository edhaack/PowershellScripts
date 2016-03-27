$script:pgSE= [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
$script:ToolWindowName = "ModuleManager"
$script:ToolTitle = "Module Manager"
$script:TopLevelMenuToPutInto = "Tools"

$script:toolWindow = $pgSE.ToolWindows | Where-Object { $_.Name -eq $script:ToolWindowName } 
if (-not $script:toolWindow ) {
	$script:toolWindow = $pgSE.ToolWindows.Add("$script:ToolWindowName")
}

. $PSScriptRoot\Add-EventHandler.ps1
. $PSScriptRoot\Set-Property.ps1
. $PSScriptRoot\New-Button.ps1
. $PSScriptRoot\New-Label.ps1
. $PSScriptRoot\New-Panel.ps1
. $PSScriptRoot\New-Listbox.ps1
. $PSScriptRoot\New-TextBox.ps1
. $PSScriptRoot\New-TrackBar.ps1
. $PSScriptRoot\New-Checkbox.ps1
. $psScriptRoot\New-Groupbox.ps1

. $PSScriptRoot\New-TreeView.ps1
. $PSScriptRoot\New-TreeNode.ps1

function Update-ModuleManager
{
	param()

$script:toolPanel = New-Panel -Tag @{
	Runspace= [Runspace]::DefaultRunspace
	ScriptRoot=  $psScriptRoot
	Refresh = {
			$psCmd = [PowerShell]::Create()
			$psCmd.Runspace = $runspace			
			$loadedModules = $psCmd.AddScript("
			Write-Progess 'Loading Module Manager' 'Getting Loaded Modules'
			Get-Module", $false).Invoke()
			$psCmd.Commands.Clear()
			$availableModules = $psCmd.AddScript("
			Write-Progess 'Loading Module Manager' 'Getting All Modules'
			Get-Module -ListAvailable", $false).Invoke()
			$psCmd.Commands.Clear()
			$allthatCanBeKnownAboutModules= $psCmd.AddScript({
Write-Progess 'Loading Module Manager' 'Extracting Module Information'
Get-Module -ListAvailable | 
	Where-Object { 
		$_.Path -like '*.psd1' -and (Test-ModuleManifest -Path $_.Path -ErrorAction SilentlyContinue)
	} |
	ForEach-Object {
		$MANIFEST =[IO.File]::ReadAllText($_.Path)
		$result = Invoke-Expression $manifest -ErrorAction SilentlyContinue		
		$result.Name = $_.Name
		$result.PSScriptRoot = Split-Path $_.Path
		New-Object PSObject -Property $result			
	} 
}, $false).Invoke()
			
			$psCmd.Commands.Clear()
			$psCmd.Dispose()			
			
			$tree = $this.Parent.Controls | Where-Object { $_.Name -eq "ModuleTree" }
			$tree.Nodes.Clear()
			foreach ($module in $availableModules) {
				$node = New-TreeNode -Text $module.Name -Tag $module.Path
				$loadedModule =$loadedModules | Where-Object  {$_.Name -eq $module.Name }
				$knownModule = $allthatCanBeKnownAboutModules | Where-Object { $_.Name -eq $module.Name } 
				if ($loadedModule ) {
					$node.BackColor = [System.Drawing.Color]::DarkGreen
					$node.ForeColor = [System.Drawing.Color]::AliceBlue

					$description = $loadedModule.Description
					if (-not $description) {
						# If the description isn't directly on the module
						# it might be in the underlying manifest information
						# This happens when one does lazy or conditional module
						# nesting (Import-Module while inside Import-Module)
						$description = $knownModule |
							Select-Object -ExpandProperty Description -Unique
					}
					if ($description) {
						$node.Nodes.Add(
"Description:
$description
")
					}

					$exportedCmds =@($loadedModule.ExportedCommands.Values)
					if ($exportedCmds) {
						$exportedCmdNode = New-TreeNode -Text "Exported Commands"
						foreach ($cmd in $exportedCmds) {
							$exportedCmdNode.Nodes.Add((New-TreeNode -Text $cmd))						
						}
						$node.Nodes.Add($exportedCmdNode)
					}
				} elseif ($knownModule) {
					$description = $knownModule |
						Select-Object -ExpandProperty Description -Unique	
					if ($description) {
						$node.Nodes.Add(
"Description:
$description
")
					}
				} 
				$null = $tree.Nodes.Add($node)
			}
				
	}
} -Controls {
	$top = 15
	$left = 15		

	New-Button -Top $top -Left $left -Width 150 -Text "Refresh" -On_Click {
		$runspace = $this.Parent.Tag.Runspace
		$ScriptRoot = $this.Parent.Tag.ScriptRoot
		New-Module {
			. $ScriptRoot\Add-EventHandler.ps1
			. $ScriptRoot\Set-Property.ps1
			. $ScriptRoot\New-TreeNode.ps1
		}
		if ($runspace.RunspaceAvailability -eq "Available") {
			. $this.Parent.Tag.Refresh.GetNewClosure()
		} else {
			
		}
	}
	
	$top += 35 
		
	New-TreeView -Top $top -Left $left -Name ModuleTree -Width 150 -Height 300 -On_NodeMouseDoubleClick {
		$runspace = $this.Parent.Tag.Runspace
		if ($runspace.RunspaceAvailability -eq "Available") {
				$psCmd = [PowerShell]::Create()
				$psCmd.Runspace = $runspace							
				if ($_.Node.Level -eq 0) {
					$moduleNode = $_.Node
				} else {
					$n = $_.Node
					while ($n.Parent) { 
						$n = $n.Parent
					}
					$moduleNode = $n
				}
								
				if ($_.Node.Level -eq 2) {
					# Exported Command - Try to edit script
					$absoluteCommandName = $moduleNode.Text + "\" + $_.Node.Text
					
					$script = "
`$ExecutionContext.InvokeCommand.GetCommand('$absoluteCommandName', 'Function') |
	Foreach-Object {
		if (-not `$_) { return }
		[Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance.DocumentWindows.Add(`$_.ScriptBlock.File)
	}
"
					$null = $psCmd.AddScript($script).BeginInvoke()
					
				} else {
					$script = "Import-Module '$($moduleNode.Tag)' -Force"
					$null = $psCmd.AddScript($script, $false).BeginInvoke()
				}
		}			
		
		
	}

	$top += 315
	
	New-Button -Text "Remove" -Top $top -Left $left -Width 150 -On_Click {
		$runspace = $this.Parent.Tag.Runspace
		if ($runspace.RunspaceAvailability -eq "Available") {
			$moduleTree = $this.Parent.Controls | 
				Where-Object { $_.Name -eq "ModuleTree"} 
			if ($moduleTree -and 
				$moduleTree.SelectedNode -and 
				$moduleTree.SelectedNode.Level -eq 0) {

				$psCmd = [PowerShell]::Create()
				$psCmd.Runspace = $runspace		
				$psCmd.AddScript("Remove-Module $($moduleTree.SelectedNode.Text)", $false).BeginInvoke()				
			}			
		}
		
			
	}
}	
$script:toolWindow.Control = $script:toolPanel 
}



Update-ModuleManager
# $script:toolWindow.Visible = $true
$script:toolWindow.Control = $script:toolPanel 
$script:toolWindow.Title = $script:ToolTitle 
$script:toolPanel.Refresh()

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
	if ($script:toolWindow) {
		$script:pgSE.ToolWindows.Remove($script:toolWindow)
	}
}

#region ShowCommand

	$showToolWindowCommand= New-Object Quest.PowerGUI.SDK.ItemCommand ("Show", "$script:ToolWindowName") 
	$sb = [ScriptBlock]::Create("" + {
# Get PowerGUI
$pgSE = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance 
# Find a tool window if one exists, and show it
}+ "
`$w = `$pgSE.ToolWindows.item('$script:ToolWindowName')
" + {
	if ($w) {
		$w.Visible = $true
	}
})	
	$showToolWindowCommand.ScriptBlock = $sb
	$showToolWindowCommand.Text = "Show $script:ToolTitle"
	$existingCommands = $pgSE.Commands | 
		Where-Object { $_.Fullname -eq "Show.$script:ToolWindowName" } 
	foreach ($cmd in $existingCommands) {
		if (-not $cmd) { continue } 
		$null = $pgSE.Commands.Remove($cmd)
	}	

	$pgSE.Commands.Add($showToolWindowCommand) 
	
#endregion

#region ShowMenuItem

	# Add the Start-Demo menu item
	$existingMenuItem  = $pgSE.Menus.Item("MenuBar.$script:TopLevelMenuToPutInto").Items |
		Where-Object { $_.Text -eq "Show $script:ToolTitle" } 
	if ($existingMenuItem) {
		foreach ($item in $existingMenuItem) { $demoMenu.Items.Remove($item) }
	}
	
	$pgSE.Menus.Item("MenuBar.$script:TopLevelMenuToPutInto").Items.Add($showToolWindowCommand) 

#endregion

#region HideCommand

	$HideToolWindowCommand= New-Object Quest.PowerGUI.SDK.ItemCommand ("Hide", "$script:ToolWindowName") 
	$sb = [ScriptBlock]::Create("" + {
# Get PowerGUI
$pgSE = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance 
# Find a tool window if one exists, and Hide it
}+ "
`$w = `$pgSE.ToolWindows.item('$script:ToolWindowName')
" + {
	if ($w) {
		$w.Visible = $false
	}
})	
	$HideToolWindowCommand.ScriptBlock = $sb
	$HideToolWindowCommand.Text = "Hide $script:ToolTitle"
	$existingCommands = $pgSE.Commands | 
		Where-Object { $_.Fullname -eq "Hide.$script:ToolWindowName" } 
	foreach ($cmd in $existingCommands) {
		if (-not $cmd) { continue } 
		$null = $pgSE.Commands.Remove($cmd)
	}	

	$pgSE.Commands.Add($HideToolWindowCommand) 
	
#endregion

#region HideMenuItem

	# Add the Start-Demo menu item
	$existingMenuItem  = $pgSE.Menus.Item("MenuBar.$script:TopLevelMenuToPutInto").Items |
		Where-Object { $_.Text -eq "Hide $script:ToolTitle" } 
	if ($existingMenuItem) {
		foreach ($item in $existingMenuItem) { $demoMenu.Items.Remove($item) }
	}
	
	$pgSE.Menus.Item("MenuBar.$script:TopLevelMenuToPutInto").Items.Add($HideToolWindowCommand) 

#endregion
