﻿function New-TrackBar {
    
    <#
    
    .Description
        Creates a new System.Windows.Forms.TrackBar
    .Synopsis
        Creates a new System.Windows.Forms.TrackBar
    .Example
        New-TrackBar
    #>

    
    
    param(
        
    [Switch]
    ${AutoSize},

    ${BackgroundImage},

    [System.Windows.Forms.ImageLayout]
    ${BackgroundImageLayout},

    ${Font},

    ${ForeColor},

    [System.Windows.Forms.ImeMode]
    ${ImeMode},

    [System.Int32]
    ${LargeChange},

    [System.Int32]
    ${Maximum},

    [System.Int32]
    ${Minimum},

    [System.Windows.Forms.Orientation]
    ${Orientation},

    ${Padding},

    [Switch]
    ${RightToLeftLayout},

    [System.Int32]
    ${SmallChange},

    [System.String]
    ${Text},

    [System.Windows.Forms.TickStyle]
    ${TickStyle},

    [System.Int32]
    ${TickFrequency},

    [System.Int32]
    ${Value},

    [System.String]
    ${AccessibleDefaultActionDescription},

    [System.String]
    ${AccessibleDescription},

    [System.String]
    ${AccessibleName},

    [System.Windows.Forms.AccessibleRole]
    ${AccessibleRole},

    [Switch]
    ${AllowDrop},

    [System.Windows.Forms.AnchorStyles]
    ${Anchor},

    ${AutoScrollOffset},

    ${BackColor},

    ${BindingContext},

    ${Bounds},

    [Switch]
    ${Capture},

    [Switch]
    ${CausesValidation},

    ${ClientSize},

    ${ContextMenu},

    ${ContextMenuStrip},

    ${Controls},

    ${Cursor},

    [System.Windows.Forms.DockStyle]
    ${Dock},

    [Switch]
    ${Enabled},

    [System.Int32]
    ${Height},

    [Switch]
    ${IsAccessible},

    [System.Int32]
    ${Left},

    ${Location},

    ${Margin},

    ${MaximumSize},

    ${MinimumSize},

    [System.String]
    ${Name},

    ${Parent},

    ${Region},

    [System.Windows.Forms.RightToLeft]
    ${RightToLeft},

    ${Site},

    ${Size},

    [System.Int32]
    ${TabIndex},

    [Switch]
    ${TabStop},

    ${Tag},

    [System.Int32]
    ${Top},

    [Switch]
    ${UseWaitCursor},

    [Switch]
    ${Visible},

    [System.Int32]
    ${Width},

    ${WindowTarget},

    [System.Management.Automation.ScriptBlock[]]
    ${On_AutoSizeChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_BackgroundImageChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_BackgroundImageLayoutChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_FontChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ForeColorChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ImeModeChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PaddingChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_TextChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Click},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DoubleClick},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseClick},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseDoubleClick},

    [System.Management.Automation.ScriptBlock[]]
    ${On_RightToLeftLayoutChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Scroll},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Paint},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ValueChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_BackColorChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_BindingContextChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_CausesValidationChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ClientSizeChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ContextMenuChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ContextMenuStripChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_CursorChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DockChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_EnabledChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_LocationChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MarginChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_RegionChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_RightToLeftChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_SizeChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_TabIndexChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_TabStopChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_VisibleChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ControlAdded},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ControlRemoved},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DragDrop},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DragEnter},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DragOver},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DragLeave},

    [System.Management.Automation.ScriptBlock[]]
    ${On_GiveFeedback},

    [System.Management.Automation.ScriptBlock[]]
    ${On_HandleCreated},

    [System.Management.Automation.ScriptBlock[]]
    ${On_HandleDestroyed},

    [System.Management.Automation.ScriptBlock[]]
    ${On_HelpRequested},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Invalidated},

    [System.Management.Automation.ScriptBlock[]]
    ${On_QueryContinueDrag},

    [System.Management.Automation.ScriptBlock[]]
    ${On_QueryAccessibilityHelp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Enter},

    [System.Management.Automation.ScriptBlock[]]
    ${On_GotFocus},

    [System.Management.Automation.ScriptBlock[]]
    ${On_KeyDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_KeyPress},

    [System.Management.Automation.ScriptBlock[]]
    ${On_KeyUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Layout},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Leave},

    [System.Management.Automation.ScriptBlock[]]
    ${On_LostFocus},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseCaptureChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseEnter},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseLeave},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseHover},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseMove},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseWheel},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Move},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewKeyDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Resize},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ChangeUICues},

    [System.Management.Automation.ScriptBlock[]]
    ${On_StyleChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_SystemColorsChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Validating},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Validated},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ParentChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Disposed}
    )
    begin {
        
    }
    process {
        
        $controlProperties = @{} + $psBoundParameters
    
        try {
        $Object = New-Object System.Windows.Forms.TrackBar 
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