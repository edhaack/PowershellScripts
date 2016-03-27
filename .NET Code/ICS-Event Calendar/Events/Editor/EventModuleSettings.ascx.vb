Option Strict On

Imports Trabon.PortalFramework.Util

Partial Class Modules_App_Events_Editor_EventModuleSettings : Inherits PortalApp.Base.PortalModuleControl

   Public Event SelectedPageViewChanged(ByVal selectedPageViewId As Integer)

   Public Sub Initialize(ByVal rsvpPageViewId As Integer)
      loadPageViewList(rsvpPageViewId)
   End Sub

   Private Sub loadPageViewList(ByVal rsvpPageViewId As Integer)
      ListHelper.LoadList(ddlRSVPPageViews, Me.CurrentPortal.GetPageViewList(Nothing), "Text", "Value", " - Select PageView - ", Nothing)
      ListHelper.SelectItem(Me.ddlRSVPPageViews, rsvpPageViewId.ToString)
   End Sub

   Protected Sub btnSaveSettings_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSaveSettings.Click
      RaiseEvent SelectedPageViewChanged(CInt(Me.ddlRSVPPageViews.SelectedValue))
   End Sub

End Class