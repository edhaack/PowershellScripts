Option Strict On

Imports App
Imports PortalApp.Util.StringUtil
Imports Trabon.PortalFramework

Partial Class Modules_App_Events_Display_EventList : Inherits PortalApp.Base.PortalControl

   Private _eventRSVP As PageView
   Public ReadOnly Property EventRSVP() As PageView
      Get
         If _eventRSVP Is Nothing Then
            _eventRSVP = Me.CurrentPortal.FindPageView(RsvpPageViewId)
         End If
         Return _eventRSVP
      End Get
   End Property

   Public Property RsvpPageViewId() As Integer
      Get
         Return CInt(Me.ViewState("RsvpPageViewId"))
      End Get
      Set(ByVal value As Integer)
         Me.ViewState("RsvpPageViewId") = value
      End Set
   End Property

   Public Overloads Sub Initialize(ByVal rsvpPageViewId As Integer)
      Me.RsvpPageViewId = rsvpPageViewId
      Me.LoadEvents()
   End Sub
   Private Sub loadEvents()
      Dim events As Generic.List(Of EventDefinition) = New EventDefinitionCollection(Me.UserContext).EventDefinitionsByPageModuleId(Me.ParentPortalModule.PageModuleId)
      If events.Count > 0 Then
         Dim availableEvents As New Generic.List(Of EventDefinition)
         Dim yesterday As Date = DateAdd(DateInterval.Day, -1, Now)
         Dim tomorrow As Date = DateAdd(DateInterval.Day, 1, Now)
         For Each e As EventDefinition In events
            If e.ExpireDate >= yesterday And e.ActiveDate <= tomorrow Or _
            e.ExpireDate = Trabon.Global.INVALID_DATE And e.ActiveDate <= tomorrow Then
               availableEvents.Add(e)
            End If
         Next
         If availableEvents.Count > 0 Then
            rEvents.DataSource = availableEvents
            rEvents.DataBind()
         Else
            NoEventsMessage()
         End If
      Else
         NoEventsMessage()
      End If
   End Sub

   Protected Sub rEvents_ItemDataBound(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.RepeaterItemEventArgs) Handles rEvents.ItemDataBound
      If e.Item.ItemType = ListItemType.Item Or e.Item.ItemType = ListItemType.AlternatingItem Or e.Item.ItemType = ListItemType.SelectedItem Then
         Dim _event As EventDefinition = CType(e.Item.DataItem, EventDefinition)
         Dim title As Label = CType(e.Item.FindControl("lblEventTitle"), Label)
         Dim location As Label = CType(e.Item.FindControl("lblLocation"), Label)
         Dim times As Label = CType(e.Item.FindControl("lblTimes"), Label)
         Dim details As Label = CType(e.Item.FindControl("lblDetails"), Label)

         Dim noTime As Label = CType(e.Item.FindControl("lblNoTime"), Label)
         Dim rsvpLink As HyperLink = CType(e.Item.FindControl("lnkRsvpLink"), HyperLink)

         Dim qp As New NameValueCollection()
         qp.Add("EventDefinitionId", _event.Id.ToString)
         Dim link As String = String.Empty
         If EventRSVP IsNot Nothing Then
            link = EventRSVP.BuildUrl(qp)
         End If

         Dim maxLength As Integer = 250
         title.Text = _event.Title
         location.Text = TruncateHTMLWithHyperlink(_event.Location, maxLength, link, "...read more.", Nothing)
         details.Text = TruncateHTMLWithHyperlink(_event.Details, maxLength, link, "...read more.", Nothing)

         rsvpLink.NavigateUrl = link

         fillTimes(_event, times, noTime, rsvpLink)
      End If
   End Sub
   Private Sub fillTimes(ByVal _event As EventDefinition, ByVal rTimes As Label, ByVal noTime As Label, ByVal rsvpLink As HyperLink)
      Dim qc As New Trabon.DataAccess.QueryCriteria
      With qc
         .OrderBy = "et.[time]"
      End With
      Dim times As Generic.List(Of EventTime) = _event.EventTimesByEventDefinitionId(qc)
      If times.Count > 0 Then
         Dim timeSB As New StringBuilder
         For Each time In times
            timeSB.Append(time.Time.ToString("f") & "<br />")
         Next
         rTimes.Text = timeSB.ToString
      Else
         rsvpLink.Visible = False
         noTime.Visible = True
      End If
   End Sub
   Private Sub NoEventsMessage()
      'Me.AddMessage("There are no events available at this time.", Trabon.UI.NotificationMessageTypes.Information)
   End Sub

End Class
