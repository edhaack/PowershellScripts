Option Strict On
Imports App
Imports System.Collections
Imports System.Web.UI.WebControls
Imports Telerik.Web.UI
Imports Trabon.PortalFramework

Partial Class Modules_App_Events_Editor_EventTimes : Inherits PortalApp.Base.PortalControl

   Private _eventDefinition As EventDefinition

   Public Event EventSaved(ByVal eventId As Integer)
   Public Event BackClick(ByVal eventId As Integer)

   Public Property EventDefinitionId() As Integer
      Get
         Return CInt(ViewState("EventDefinitionId"))
      End Get
      Set(ByVal value As Integer)
         ViewState("EventDefinitionId") = value.ToString
      End Set
   End Property
   Public Property EventDefinition() As EventDefinition
      Get
         If _eventDefinition Is Nothing Then
            _eventDefinition = New EventDefinition(Me.EventDefinitionId, Me.UserContext)
         End If
         Return _eventDefinition
      End Get
      Set(ByVal value As EventDefinition)
         _eventDefinition = value
      End Set
   End Property

   Public Sub Initialize(ByVal eventDefinitionId As Integer)
      Me.EventDefinitionId = eventDefinitionId
      Me.loadEvent()
   End Sub

   Protected Sub btnSubmit_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSubmit.Click
      saveEvent()
      RaiseEvent EventSaved(Me.EventDefinitionId)
   End Sub
   Protected Sub btnSaveNewDateTime_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSaveNewDateTime.Click
      saveNewDateTime()
   End Sub
   Protected Sub btnUpdateDateTime_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnUpdateDateTime.Click
      If Not String.IsNullOrEmpty(btnUpdateDateTime.CommandArgument) Then
         Dim eventTimeId As Integer = CInt(btnUpdateDateTime.CommandArgument)
         updateDateTime(eventTimeId)
      End If
   End Sub
   Protected Sub btnCreateNewDateTime_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnCreateNewDateTime.Click
      showNewDateTime()
   End Sub
   Protected Sub lbtnBack_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lbtnBack.Click
      RaiseEvent BackClick(Me.EventDefinitionId)
   End Sub

   Protected Sub rTimes_ItemDataBound(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.RepeaterItemEventArgs) Handles rTimes.ItemDataBound
      Select Case e.Item.ItemType
         Case ListItemType.AlternatingItem, ListItemType.Item, ListItemType.SelectedItem
            Dim time As Label = CType(e.Item.FindControl("lblTime"), Label)
            Dim timeEditBtn As Button = CType(e.Item.FindControl("btnTimeEdit"), Button)
            Dim timeDeleteBtn As Button = CType(e.Item.FindControl("btnTimeDelete"), Button)
            Dim t As EventTime = CType(e.Item.DataItem, EventTime)

            time.Text = t.Time.ToString
            timeEditBtn.CommandArgument = t.EventTimeId.ToString
            timeEditBtn.CommandName = "Edit"
            timeDeleteBtn.CommandArgument = t.EventTimeId.ToString
            timeDeleteBtn.CommandName = "Delete"
      End Select
   End Sub
   Protected Sub rTimes_ItemCommand(ByVal source As Object, ByVal e As System.Web.UI.WebControls.RepeaterCommandEventArgs) Handles rTimes.ItemCommand
      Dim eventTimeId As Integer = Trabon.Global.INVALID_ID
      Integer.TryParse(e.CommandArgument.ToString, eventTimeId)
      Select Case e.CommandName.ToString
         Case "Edit"
            showEditDateTime(eventTimeId)
         Case "Delete"
            deleteTime(eventTimeId)
      End Select
   End Sub

   Private Sub loadEvent()
      hideButtonsAndLabels()
      If Me.EventDefinitionId <> Trabon.Global.INVALID_ID Then
         Dim _event As New EventDefinition(Me.EventDefinitionId, Me.UserContext)
         lblEventId.Text = _event.Id.ToString
         Title.Text = _event.Title
         If _event.ActiveDate = Trabon.Global.INVALID_DATE Then
            activeDate.SelectedDate = Now
            activeDate.FocusedDate = Now
         Else
            activeDate.SelectedDate = _event.ActiveDate
            activeDate.FocusedDate = _event.ActiveDate
         End If

         expiration.Items(0).Attributes.Add("OnClick", "ToggleDatePicker(true)")
         expiration.Items(1).Attributes.Add("OnClick", "ToggleDatePicker(false)")
         If _event.ExpireDate = Trabon.Global.INVALID_DATE Then
            expiration.Items(0).Selected = False
            expiration.Items(1).Selected = True
            expireDate.Attributes.Add("style", "display:none;")
            expireDate.SelectedDate = Now()
            expireDate.FocusedDate = Now()
         Else
            expiration.Items(0).Selected = True
            expiration.Items(1).Selected = False
            expireDate.SelectedDate = _event.ExpireDate
            expireDate.FocusedDate = _event.ExpireDate
            expireDate.Style("display") = "block"
         End If
         loadEventTimes(_event)
      End If
   End Sub
   Private Sub loadEventTimes(ByVal _event As EventDefinition)
      Dim qc As New Trabon.DataAccess.QueryCriteria
      With qc
         .OrderBy = "et.[time]"
      End With
      Dim times As Generic.List(Of EventTime) = _event.EventTimesByEventDefinitionId(qc)
      If times.Count > 0 Then
         rTimes.DataSource = times
         rTimes.DataBind()

         rTimes.Visible = True
         noTime.Visible = False
      Else
         rTimes.Visible = False
         noTime.Visible = True
      End If
   End Sub

   Private Sub saveEvent()
      Dim _event As New EventDefinition(Me.EventDefinitionId, Me.UserContext)
      If activeDate.SelectedDate.ToString <> "" Then
         _event.ActiveDate = activeDate.SelectedDate
      Else
         Me.AddMessage("Acitvation date must be set.", Trabon.UI.NotificationMessageTypes.Error)
         Exit Sub
      End If
      If expiration.Items(1).Selected Then
         _event.ExpireDate = Trabon.Global.INVALID_DATE
      Else
         If expireDate.SelectedDate.ToString <> "" Then
            _event.ExpireDate = expireDate.SelectedDate
         Else
            Me.AddMessage("Expiration date must be set.", Trabon.UI.NotificationMessageTypes.Error)
            Exit Sub
         End If
      End If
      _event.Save()
   End Sub
   Private Sub showNewDateTime()
      newDate.Visible = True
      newDate.SelectedDate = Now
      newDate.FocusedDate = Now
      newTime.Visible = True
      newTime.SelectedDate = Now
      newTime.FocusedDate = Now
      btnSaveNewDateTime.Visible = True
      btnUpdateDateTime.Visible = False
      lblEditTime.Visible = False
      lblNewTime.Visible = True
   End Sub
   Private Sub showEditDateTime(ByVal eventTimeId As Integer)
      Dim et As New EventTime(eventTimeId, Me.UserContext)
      newDate.Visible = True
      newDate.SelectedDate = et.Time
      newDate.FocusedDate = et.Time
      newTime.Visible = True
      newTime.SelectedDate = et.Time
      newTime.FocusedDate = et.Time
      btnSaveNewDateTime.Visible = False
      btnUpdateDateTime.Visible = True
      lblEditTime.Visible = True
      lblNewTime.Visible = False
      btnUpdateDateTime.CommandArgument = eventTimeId.ToString
   End Sub
   Private Sub hideNewDateTime()
      newDate.Visible = False
      newTime.Visible = False
      btnSaveNewDateTime.Visible = False
   End Sub
   Private Sub hideButtonsAndLabels()
      btnSaveNewDateTime.Visible = False
      btnUpdateDateTime.Visible = False
      lblEditTime.Visible = False
      lblNewTime.Visible = False
   End Sub
   Private Function getTimeFromCtrls(ByVal d As RadCalendar, ByVal t As RadTimePicker) As Date
      Dim _date As Date = d.SelectedDate
      Dim _time As Date = CDate(t.SelectedDate)
      Dim _dateTime As Date = CDate(_date.ToShortDateString & " " & _time.ToShortTimeString)
      Return _dateTime
   End Function

   Private Sub saveNewDateTime()
      Dim et As New EventTime(Me.UserContext)
      et.EventDefinitionId = Me.EventDefinitionId
      et.Time = getTimeFromCtrls(newDate, newTime)
      et.Save()
      hideNewDateTime()
      Me.loadEvent()
   End Sub
   Private Sub updateDateTime(ByVal eventTimeId As Integer)
      Dim et As New EventTime(eventTimeId, Me.UserContext)
      et.Time = getTimeFromCtrls(newDate, newTime)
      et.Save()
      hideNewDateTime()
      Me.loadEvent()
   End Sub
   Private Sub deleteTime(ByVal eventTimeId As Integer)
      Dim et As New EventTime(eventTimeId, Me.UserContext)
      et.Delete()
      Me.loadEvent()
   End Sub

End Class