Option Strict On

Imports App
Imports System.Collections

Partial Class Modules_App_Events_Editor_EventRegistrants : Inherits PortalApp.Base.PortalControl

   Private _eventDefinition As EventDefinition

   Public Event ReturnClick()

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
      Me.loadEventRegistrants()
   End Sub
   Protected Sub lbtnBack_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lbtnBack.Click
      RaiseEvent ReturnClick()
   End Sub
   Protected Sub btnSaveToExcel_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSaveToExcel.Click

      Dim bc As BoundColumn
      Dim dg As New DataGrid
      dg.AutoGenerateColumns = False

      bc = New BoundColumn
      bc.DataField = "FirstName"
      bc.HeaderText = "First"
      dg.Columns.Add(bc)

      bc = New BoundColumn
      bc.DataField = "LastName"
      bc.HeaderText = "Last"
      dg.Columns.Add(bc)

      bc = New BoundColumn
      bc.DataField = "Address"
      bc.HeaderText = "Address"
      dg.Columns.Add(bc)

      bc = New BoundColumn
      bc.DataField = "City"
      bc.HeaderText = "City"
      dg.Columns.Add(bc)

      bc = New BoundColumn
      bc.DataField = "State"
      bc.HeaderText = "State"
      dg.Columns.Add(bc)

      bc = New BoundColumn
      bc.DataField = "Zip"
      bc.HeaderText = "Zip"
      dg.Columns.Add(bc)

      bc = New BoundColumn
      bc.DataField = "Phone"
      bc.HeaderText = "Phone"
      dg.Columns.Add(bc)

      bc = New BoundColumn
      bc.DataField = "Email"
      bc.HeaderText = "Email"
      dg.Columns.Add(bc)

      bc = New BoundColumn
      bc.DataField = "AttendeeCount"
      bc.HeaderText = "Attendees"
      dg.Columns.Add(bc)

      bc = New BoundColumn
      bc.DataField = "CreatedDtTm"
      bc.HeaderText = "Registration Date"
      dg.Columns.Add(bc)

      dg.DataSource = Me.getEventRegistrants
      dg.DataBind()

      Response.ClearHeaders()
      PortalApp.Util.HttpResponseWriter.WriteControlAs(dg, "application/vnd.ms-excel", Nothing, Nothing, Response)
   End Sub
   Protected Sub grdEventRegistrants_NeedDataSource(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles grdEventRegistrants.NeedDataSource
      Me.grdEventRegistrants.DataSource = Me.getEventRegistrants
   End Sub

   Private Sub loadEventDetail()

      With Me.EventDefinition
         Title.Text = .Title
         lblLocation.Text = .Location
         lblDetails.Text = .Details
         Dim timeSB As New StringBuilder
         Dim ts As Generic.List(Of EventTime) = .EventTimesByEventDefinitionId
         For Each t As EventTime In ts
            timeSB.Append(t.Time.ToString & "<br />")
         Next
         lblTimes.Text = timeSB.ToString
      End With

      'Show event details
      Me.pnlEventDetails.Visible = True

   End Sub
   Private Sub loadEventRegistrants()

      Dim registrants As Generic.List(Of EventRegistration) = Me.getEventRegistrants
      If registrants.Count > 0 Then

         Me.grdEventRegistrants.DataSource = registrants
         Me.grdEventRegistrants.DataBind()
      Else
         Me.AddMessage("There are no registrants for this event.", Trabon.UI.NotificationMessageTypes.Information)
      End If

   End Sub
   Private Function getEventRegistrants() As Generic.List(Of EventRegistration)
      Dim registrants As Generic.List(Of EventRegistration)
      Dim erc As New EventRegistrationCollection(Me.UserContext)
      Dim qc As New Trabon.DataAccess.QueryCriteria
      If EventDefinition.Id <> Trabon.Global.INVALID_ID Then

         'Show event details
         Me.loadEventDetail()

         registrants = EventDefinition.RegistrantsByPageModuleId()
      Else

         'Hide event details
         Me.pnlEventDetails.Visible = False

         erc = New EventRegistrationCollection(Me.UserContext)
         qc = New Trabon.DataAccess.QueryCriteria
         qc.IncludeInactiveResults = True
         qc.Where = "is_active = 0"

         registrants = erc.ReadAll(qc)

      End If
      Return registrants
   End Function

End Class