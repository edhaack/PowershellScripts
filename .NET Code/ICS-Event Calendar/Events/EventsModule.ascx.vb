Option Strict On

Imports App
Imports Trabon.PortalFramework
Imports System.Transactions
Imports Trabon.DataAccess
Imports Trabon

Partial Class Modules_App_Events_EventsModule : Inherits PortalApp.Base.EditablePortalModuleControl

   Private _rSVPPageViewIdSetting As PageModuleSetting
   Public ReadOnly Property RSVPPageViewIdSetting() As PageModuleSetting
      Get
         If _rSVPPageViewIdSetting Is Nothing Then
            _rSVPPageViewIdSetting = Me.GetSetting("RSVPPageViewId")
         End If
         Return _rSVPPageViewIdSetting
      End Get
   End Property
   Public ReadOnly Property RSVPPageViewId() As Integer
      Get
         Dim returnValue As Integer
         Integer.TryParse(Me.RSVPPageViewIdSetting.SettingValue, returnValue)
         Return returnValue
      End Get
   End Property


   Protected Overrides Sub loadContent()
      portalEventList.Initialize(Me.RSVPPageViewId)
   End Sub
   Protected Overrides Sub loadEditor()
      pnlDisplay.Visible = False
      pnlEdit.Visible = True
      Me.rtsEventTabs.SelectedIndex = 0
      Me.loadEvents()
   End Sub

   Protected Sub rtsEventTabs_TabClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadTabStripEventArgs) Handles rtsEventTabs.TabClick
      Select Case e.Tab.Value

         Case "Manage"
            Me.loadEvents()
         Case "ModuleSettings"
            Me.showModuleSettings()
         Case "Archived"
            Me.loadArchivedEvents()
         Case "Instructions"
            Me.showSetupInstructions()

      End Select
   End Sub
   Protected Sub portalEventRsvpSetup_SelectedPageViewChanged(ByVal selectedPageViewId As Integer) Handles portalEventModuleSettings.SelectedPageViewChanged
      Me.RSVPPageViewIdSetting.SettingValue = selectedPageViewId.ToString
      Me.RSVPPageViewIdSetting.Save()
   End Sub
   Protected Sub btnReturn_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnReturn.Click
      Me.ReturnFromEditMode(True)
   End Sub

   Private Sub loadEvents()
      Me.hideAll()
      Me.portalEventEditor.Visible = True
      Me.portalEventEditor.Initialize(Me.PageModuleId, False)
   End Sub
   Private Sub loadArchivedEvents()
      Me.hideAll()
      Me.portalEventEditor.Visible = True
      Me.portalEventEditor.Initialize(Me.PageModuleId, True)
   End Sub
   Private Sub showModuleSettings()
      Me.hideAll()
      Me.portalEventModuleSettings.Visible = True
      Me.portalEventModuleSettings.Initialize(Me.RSVPPageViewId)
   End Sub
   Private Sub showSetupInstructions()
      Me.hideAll()
      Me.portalEventModuleInstructions.Visible = True
   End Sub
   Private Sub hideAll()
      Me.portalEventEditor.Visible = False
      Me.portalEventModuleSettings.Visible = False
      Me.portalEventModuleInstructions.Visible = False
   End Sub

   Public Overrides Function CascadingDelete() As Boolean
      Dim returnValue As Boolean
      Using scope As TransactionScope = TransactionHelper.GetTransactionScope()
         Try
            Dim eds As Generic.List(Of EventDefinition) = New EventDefinitionCollection(Me.UserContext).EventDefinitionsByPageModuleId(Me.PageModuleId)
            For Each ed In eds
               ed.Delete()
            Next
            returnValue = MyBase.CascadingDelete()
         Catch ex As Exception
            returnValue = False
            Throw New BaseException(ex.Message, ex)
         Finally
            If returnValue = True Then
               TransactionHelper.CompleteTransactionScope(scope)
            End If
         End Try
      End Using
      Return returnValue
   End Function

End Class