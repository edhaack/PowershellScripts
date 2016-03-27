Option Strict On
Imports App
Imports PortalApp.Configuration
Imports PortalApp.Resource
Imports PortalApp.Util
Imports System.IO
Imports System.Text
Imports Trabon.PortalFramework.Util
Imports Trabon.PortalFramework

Partial Class Modules_App_Events_Email_EventForm : Inherits PortalApp.Base.PortalModuleEntityComponent
	Private _entityId As Integer = Trabon.Global.INVALID_ID
	Public Property EntityId() As Integer
		Get
			Dim vsEntityId As String = String.Empty
			Try
				vsEntityId = ViewState("EntityId").ToString
				Integer.TryParse(vsEntityId, _entityId)
			Catch ex As Exception

			End Try
			Return _entityId
		End Get
		Set(ByVal value As Integer)
			_entityId = value
			ViewState("EntityId") = value.ToString
		End Set
	End Property
	Private _eventDefinition As EventDefinition
	Public Property EventDefinition() As EventDefinition
		Get
			Return _eventDefinition
		End Get
		Set(ByVal value As EventDefinition)
			_eventDefinition = value
		End Set
	End Property
	Private _registrant As EventRegistration
	Public Property Registrant() As EventRegistration
		Get
			Return _registrant
		End Get
		Set(ByVal value As EventRegistration)
			_registrant = value
		End Set
	End Property

	Private _isReadOnly As Boolean = True
	Public Property IsReadOnly() As Boolean
		Get
			Return _isReadOnly
		End Get
		Set(ByVal value As Boolean)
			_isReadOnly = value
		End Set
	End Property
	Public ReadOnly Property Display() As String
		Get
			loadForEmailDisplay()
			Dim sb As New StringBuilder
			Dim hw As New HtmlTextWriter(New StringWriter(sb))
			Me.RenderControl(hw)
			Return sb.ToString
		End Get
	End Property
	Public Overrides ReadOnly Property EntityTypeName() As String
		Get
			Return "EventRegistration"
		End Get
	End Property

	Public ValidationGroup As String = "RSVPFormValidation"

	Public Overrides Sub Initialize(ByVal entityId As Integer)
		Me.EntityId = entityId
	End Sub
	Public Overrides Sub LoadFormValues()
		Me.AddMessage("Please use the overloaded version of LoadFormValues.", Trabon.UI.NotificationMessageTypes.Failure)
	End Sub
	Public Overloads Sub LoadFormValues(ByVal defaultState As String, ByVal eventListing As PageView)
		lblEventDefinitionId.Text = Me.EntityId.ToString

		EventDefinition = New EventDefinition(Me.EntityId, Me.UserContext)

		Dim states As Generic.List(Of Trabon.CodeValue) = Me.PortalCodeSetManager.GetCodes(CodeSetManager.CachedCodeSet.StateCode, Me.PortalId)
		ListHelper.LoadList(ddlState, states, "CodeValueDisplay", "CodeValueDisplay", defaultState, defaultState)

		If eventListing IsNot Nothing Then
			returnToEvents.NavigateUrl = eventListing.BuildUrl
		End If
		If EventDefinition.Id <> Trabon.Global.INVALID_ID Then
			With EventDefinition
				lblTitle.Text = .Title
				lblLocation.Text = .Location
				lblDetails.Text = .Details
				lblEventDefinitionId.Text = .Id.ToString
			End With
			
			'Save current event definition for later use (download ICS File)
			CurrentPortalSession.CurrentEventDefinition = _eventDefinition

			Dim qc As New Trabon.DataAccess.QueryCriteria
			With qc
				.OrderBy = "et.[time]"
			End With
			Dim ts As Generic.List(Of EventTime) = EventDefinition.EventTimesByEventDefinitionId(qc)
			If ts.Count > 0 Then
				For Each t In ts
					Dim li As New ListItem(t.Time.ToString("f"), t.Id.ToString)
					chklstTimes.Items.Add(li)
				Next
			Else
				noTime.Visible = True
			End If
		End If
	End Sub
	Public Overrides Sub RetrieveFormValues()
		Registrant = New EventRegistration(Me.UserContext)
		With Registrant
			.FirstName = ttbFirstName.Text.Trim
			.LastName = ttbLastName.Text.Trim
			.Address = ttbAddress.Text.Trim
			.City = ttbCity.Text.Trim
			.State = ddlState.SelectedItem.Text
			.Zip = ttbZip.Text.Trim
			.Phone = ttbPhone.Text.Trim
			.Email = ttbEmail.Text.Trim
			.AttendeeCount = CInt(ddlAttendees.SelectedItem.ToString)
		End With
	End Sub

	Public Function ProcessForm() As ReturnValue
		Dim retval As New ReturnValue
		If FormIsValid(ValidationGroup) Then
			If aTimeIsSelected() Then
				retval = saveRegistrant()
				If retval.Success Then
					If Registrant.Id <> Trabon.Global.INVALID_ID Then
						Dim tId As Integer = Trabon.Global.INVALID_ID
						For Each li As ListItem In chklstTimes.Items
							If li.Selected Then
								Integer.TryParse(li.Value, tId)
								saveTimeRegisteredFor(tId)
							End If
						Next
					Else
						retval.ErrorMessage = "Registrant id is invalid."
					End If
				End If
			Else
				retval.ErrorMessage = "You must select a time to register for."
			End If
		Else
			RSVPFormValidationSummary.Visible = True
			retval.ErrorMessage = "The form is not valid."
		End If
		Return retval
	End Function

	Private Function saveRegistrant() As ReturnValue
		Dim retVal As New ReturnValue
		Try
			Me.RetrieveFormValues()
			Registrant.Save()
			lblRegistrationId.Text = Registrant.EventRegistrationId.ToString
			'Save current event rsvp page for use in the ICS file
			'Gets the base url in the following format: "http(s)://domain(:port)/AppPath)"
			Dim url = HttpContext.Current.Request.Url.Scheme + "://" + HttpContext.Current.Request.Url.Authority + HttpContext.Current.Request.Url.PathAndQuery
			CurrentPortalSession.CurrentEventUrl = url
		Catch ex As Exception
			retVal.ErrorMessage = ex.Message
		End Try

		Return retVal
	End Function
	Private Sub saveTimeRegisteredFor(ByVal tId As Integer)
		Dim t As New EventTime(tId, Me.UserContext)
		t.AddRegistrant(Registrant.Id)
		Dim isSuccessful  = t.Save()

		If (Not isSuccessful) Then Return
		'Save this event time to session for thank you page...
		dim times = CurrentPortalSession.EventTimes
		times.Add(t)
	End Sub
	Private Function aTimeIsSelected() As Boolean
		Dim result As Boolean = False
		For Each t As ListItem In chklstTimes.Items
			If t.Selected Then
				result = True
				Exit For
			End If
		Next
		Return result
	End Function

	Private Sub loadForEmailDisplay()
		returnToEvents.Visible = False
		pnlInputForm.Visible = False
		pnlOutputForm.Visible = True

		Dim eventDefinitionId As Integer
		Integer.TryParse(lblEventDefinitionId.Text, eventDefinitionId)
		Dim registrationId As Integer
		Integer.TryParse(lblRegistrationId.Text, registrationId)

		EventDefinition = New EventDefinition(eventDefinitionId, Me.UserContext)
		Registrant = New EventRegistration(registrationId, Me.UserContext)

		If Registrant.Id <> Trabon.Global.INVALID_ID And EventDefinition.Id <> Trabon.Global.INVALID_ID Then
			With EventDefinition
				lblTitle.Text = .Title
				lblLocation.Text = .Location
				lblDetails.Text = .Details
			End With
			With Registrant
				lblFirstName.Text = .FirstName
				lblLastName.Text = .LastName
				lblAddress.Text = .Address
				lblCity.Text = .City
				lblState.Text = .State
				lblZip.Text = .Zip
				lblPhone.Text = .Phone
				lblEmail.Text = .Email
				lblAttendees.Text = .AttendeeCount.ToString

				Dim ets As Generic.List(Of EventTime) = New EventTimeCollection(Me.UserContext).EventTimesByEventRegistrationId(.Id)
				Dim sb As New StringBuilder
				For Each et As EventTime In ets
					sb.Append(et.Time.ToString & "<br />")
				Next
				lblTimes.Text = sb.ToString
			End With
		Else
			AddMessage("Event or registrant cannot be read.", Trabon.UI.NotificationMessageTypes.Error)
		End If
	End Sub

	Public Overrides Function FormIsValid(ByVal validationGroup As String) As Boolean
		If String.IsNullOrEmpty(validationGroup) Then
			validationGroup = Me.ValidationGroup
		End If
		Page.Validate(validationGroup)
		Return Page.IsValid
	End Function
End Class