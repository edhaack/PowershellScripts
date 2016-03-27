function New-TreeNode {
    
    <#
    
    .Description
        Creates a new System.Windows.Forms.TreeNode
    .Synopsis
        Creates a new System.Windows.Forms.TreeNode
    .Example
        New-TreeNode
    #>

    
    
    param(
        
    ${BackColor},

    [Switch]
    ${Checked},

    ${ContextMenu},

    ${ContextMenuStrip},

    ${ForeColor},

    [System.Int32]
    ${ImageIndex},

    [System.String]
    ${ImageKey},

    ${NodeFont},

    ${Nodes},

    [System.Int32]
    ${SelectedImageIndex},

    [System.String]
    ${SelectedImageKey},

    [System.String]
    ${StateImageKey},

    [System.Int32]
    ${StateImageIndex},

    ${Tag},

    [System.String]
    ${Text},

    [System.String]
    ${ToolTipText},

    [System.String]
    ${Name}
    )
    begin {
        
    }
    process {
        
        $controlProperties = @{} + $psBoundParameters
    
        try {
        $Object = New-Object System.Windows.Forms.TreeNode 
        Set-Property -inputObject $Object -property $controlProperties
        } catch {
            Write-Error $_
            return
        } 
        $Object
    }
    end {
        
    }
}