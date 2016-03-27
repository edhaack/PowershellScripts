Option Strict On
Imports App
Imports PortalApp.Util.StringUtil
Imports System.Collections
Imports System.Web.UI.WebControls
Imports Trabon.PortalFramework
Imports Trabon.DataAccess

Partial Class Modules_App_Events_Editor_Events : Inherits PortalApp.Base.PortalControl

   Private _pageModuleId As Integer = Trabon.Global.INVALID_ID
   Private _maxLength As Integer = 250

   Public Property IsArchiveView() As Boolean
      Get
         Return CBool(Me.ViewState("IsArchiveView"))
      End Get
      Set(ByVal value As Boolean)
         Me.ViewState("IsArchiveView") = value
      End Set
   End Property
   Public Property PageModuleId() As Integer
      Get
         Dim vsPageModuleId As String = String.Empty
         Try
            vsPageModuleId = ViewState("PageModuleId").ToString
            Integer.TryParse(vsPageModuleId, _pageModuleId)
         Catch ex As Exception

         End Try
         Return _pageModuleId
      End Get
      Set(ByVal value As Integer)
         _pageModuleId = value
         ViewState("PageModuleId") = value.ToString
      End Set
   End Property

   Public Overloads Sub Initialize(ByVal entityId As Integer, ByVal isArchiveView As Boolean)
      Me.PageModuleId = entityId
      Me.IsArchiveView = isArchiveView
      Me.loadEventsList()

      Me.UsePrivateMessages = True

   End Sub

   Protected Sub btnAddEvent_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnAddEvent.Click
      Me.loadEventDetails(Nothing)
   End Sub
   Protected Sub rptEvents_ItemDataBound(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.RepeaterItemEventArgs) Handles rptEvents.ItemDataBound
      If e.Item.ItemType = ListItemType.Item Or e.Item.ItemType = ListItemType.AlternatingItem Or e.Item.ItemType = ListItemType.SelectedItem Then
         Dim _event As EventDefinition = CType(e.Item.DataItem, EventDefinition)

         Dim title As Label = CType(e.Item.FindControl("lblEventTitle"), Label)
         Dim location As Label = CType(e.Item.FindControl("lblLocation"), Label)
         Dim details As Label = CType(e.Item.FindControl("lblDetails"), Label)
         Dim times As Label = CType(e.Item.FindControl("lblTimes"), Label)

         Dim editEvent As LinkButton = CType(e.Item.FindControl("lbtnEditEvent"), LinkButton)
         Dim archiveEvent As LinkButton = CType(e.Item.FindControl("lbtnArchiveEvent"), LinkButton)
         Dim deleteEvent As LinkButton = CType(e.Item.FindControl("lbtnDeleteEvent"), LinkButton)
         Dim viewRegistrants As LinkButton = CType(e.Item.FindControl("lbtnViewRegistrants"), LinkButton)

         title.Text = _event.Title
         location.Text = TruncateHTMLWithHyperlink(_event.Location, _maxLength, Nothing, "...", Nothing)
         details.Text = TruncateHTMLWithHyperlink(_event.Details, _maxLength, Nothing, "...", Nothing)
         fillTimes(_event, times, times)

         archiveEvent.CommandArgument = _event.Id.ToString
         If Me.IsArchiveView Then
            archiveEvent.Text = "Unarchive Event"
            archiveEvent.CommandName = "UnarchiveEvent"
         Else
            archiveEvent.Text = "Archive Event"
            archiveEvent.CommandName = "ArchiveEvent"
         End If

         viewRegistrants.CommandName = "ViewRegistrants"
         viewRegistrants.CommandArgument = _event.Id.ToString
         editEvent.CommandName = "EventDetails"
         editEvent.CommandArgument = _event.Id.ToString
         deleteEvent.CommandName = "DeleteEvent"
         deleteEvent.CommandArgument = _event.Id.ToString
      End If
   End Sub
   Protected Sub rptEvents_ItemCommand(ByVal source As Object, ByVal e As System.Web.UI.WebControls.RepeaterCommandEventArgs) Handles rptEvents.ItemCommand
      Dim eventId As Integer = CInt(e.CommandArgument)
      Select Case e.CommandName
         Case "ShowTimes"
            Me.loadEventTimes(eventId)
         Case "EventDetails"
            Me.loadEventDetails(eventId)
         Case "ArchiveEvent"
            Me.manageArchiveState(eventId, False)
         Case "UnarchiveEvent"
            Me.manageArchiveState(eventId, True)
         Case "ViewRegistrants"
            Me.loadEventRegistrants(eventId)
         Case "DeleteEvent"
            Me.deleteEvent(eventId)
      End Select
   End Sub
   Protected Sub portalEventDetails_NextClick(ByVal eventId As Integer) Handles portalEventDetails.NextClick
      Me.loadEventTimes(eventId)
   End Sub
   Protected Sub portalEventDetails_ReturnClick() Handles portalEventDetails.ReturnClick
      Me.loadEventsList()
   End Sub
   Protected Sub portalEventTimes_BackClick(ByVal eventId As Integer) Handles portalEventTimes.BackClick
      Me.loadEventDetails(eventId)
   End Sub
   Protected Sub portalEventTimes_EventSaved(ByVal eventId As Integer) Handles portalEventTimes.EventSaved
      Me.AddMessage("Event saved successfully.", Trabon.UI.NotificationMessageTypes.Success, Me.mcEventMessages.MessageGroup)
      Me.loadEventsList()
   End Sub
   Protected Sub portalEventRegistrants_ReturnClick() Handles portalEventRegistrants.ReturnClick
      Me.loadEventsList()
   End Sub

   Private Sub loadEventsList()
      Dim ec As New EventDefinitionCollection(Me.UserContext)
      Dim events As Generic.List(Of EventDefinition)

      If IsArchiveView Then
         Dim qc As New QueryCriteria
         qc.IncludeInactiveResults = True
         qc.BuildWhereClause("active_ind", 0, False, QueryCriteria.LogicalOperator.And)
         events = ec.EventDefinitionsByPageModuleId(Me.PageModuleId, qc)
         Me.btnAddEvent.Visible = False
      Else
         events = ec.EventDefinitionsByPageModuleId(Me.PageModuleId)
         Me.btnAddEvent.Visible = True
      End If

      If events.Count > 0 Then
         rptEvents.DataSource = events
         rptEvents.DataBind()
         rptEvents.Visible = True
         noEvents.Visible = False
      Else
         rptEvents.Visible = False
         noEvents.Visible = True
      End If

      Me.hideAll()
      Me.pnlEventList.Visible = True

   End Sub
   Private Sub loadEventTimes(ByVal eventDefinitionId As Integer)
      hideAll()
      portalEventTimes.Visible = True
      portalEventDetails.Visible = False
      portalEventTimes.Initialize(eventDefinitionId)
   End Sub
   Private Sub loadEventDetails(ByVal eventDefinitionId As Integer)
      hideAll()
      portalEventDetails.Visible = True
      portalEventDetails.Initialize(eventDefinitionId)
   End Sub
   Private Sub loadEventRegistrants(ByVal eventDefinitionId As Integer)
      hideAll()
      portalEventRegistrants.Visible = True
      portalEventRegistrants.Initialize(eventDefinitionId)
   End Sub

   Private Sub hideAll()
      Me.pnlEventList.Visible = False
      Me.portalEventDetails.Visible = False
      Me.portalEventRegistrants.Visible = False
      Me.portalEventTimes.Visible = False
   End Sub
   Private Sub manageArchiveState(ByVal eventDefinitionId As Integer, ByVal activate As Boolean)
      Dim e As New EventDefinition(eventDefinitionId, Me.UserContext)
      If e.Id <> Trabon.Global.INVALID_ID Then
         If activate Then
            Me.AddMessage("Event restored successfully.", Trabon.UI.NotificationMessageTypes.Success, Me.mcEventMessages.MessageGroup)
            e.Restore()
         Else
            Me.AddMessage("Event archived successfully.", Trabon.UI.NotificationMessageTypes.Success, Me.mcEventMessages.MessageGroup)
            e.InActivate()
         End If
      Else
         Me.AddMessage("Event update failed, contact administrator", Trabon.UI.NotificationMessageTypes.Error)
      End If
      Me.loadEventsList()
   End Sub
   Private Sub deleteEvent(ByVal eventDefinitionId As Integer)
      Dim e As New EventDefinition(eventDefinitionId, Me.UserContext)
      If e.Id <> Trabon.Global.INVALID_ID Then



         e.Delete()




         Me.AddMessage("Event deleted.", Trabon.UI.NotificationMessageTypes.Success, Me.mcEventMessages.MessageGroup)
         Me.loadEventsList()
      Else
         Me.AddMessage("Event update failed, contact administrator", Trabon.UI.NotificationMessageTypes.Error)
      End If
   End Sub
   Private Sub fillTimes(ByVal _event As EventDefinition, ByVal rTimes As Label, ByVal noTime As Label)
      Dim qc As New Trabon.DataAccess.QueryCriteria
      With qc
         .OrderBy = "et.[time]"
      End With
      Dim times As Generic.List(Of EventTime) = _event.EventTimesByEventDefinitionId(qc)
      If times.Count > 0 Then
         Dim timeSB As New StringBuilder
         For Each time In times
            timeSB.Append(time.Time.ToString & "<br />")
         Next
         rTimes.Text = timeSB.ToString
      Else
         noTime.Visible = True
      End If
   End Sub

End Class