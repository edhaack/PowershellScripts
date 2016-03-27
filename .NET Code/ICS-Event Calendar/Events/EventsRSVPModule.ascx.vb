Option Strict On
Imports App
Imports PortalApp.Util
Imports Trabon.PortalFramework.Util
Imports PortalApp.Resource
Imports Trabon.PortalFramework
Partial Class Modules_App_Events_EventsRSVPModule : Inherits PortalApp.Base.EditablePortalModuleControl

	Private _entityId As Integer = Trabon.Global.INVALID_ID
	Private _eventDefinition As EventDefinition
	Private _emailRecipient As PageModuleSetting
	Private _emailCCRecipient As PageModuleSetting
	Private _emailBCCRecipient As PageModuleSetting
	Private _emailFromAddress As PageModuleSetting
	Private _emailUserSubject As PageModuleSetting
	Private _emailAdminSubject As PageModuleSetting
	Private _eventListingUrl As PageModuleSetting
	Private _redirectUrl As PageModuleSetting
	Private _thankYouMessage As HtmlContent
	Private _thankYouMessageHtmlContentIdSetting As PageModuleSetting
	Private _adminMessage As HtmlContent
	Private _adminMessageHtmlContentIdSetting As PageModuleSetting
	Private _defaultState As PageModuleSetting

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
	Public Property EventDefinition() As EventDefinition
		Get
			Return _eventDefinition
		End Get
		Set(ByVal value As EventDefinition)
			_eventDefinition = value
		End Set
	End Property

	Public ReadOnly Property EmailRecipient() As PageModuleSetting
		Get
			If _emailRecipient Is Nothing Then
				_emailRecipient = Me.GetSetting("EmailRecipient")
			End If
			Return _emailRecipient
		End Get
	End Property
	Public ReadOnly Property EmailCCRecipient() As PageModuleSetting
		Get
			If _emailCCRecipient Is Nothing Then
				_emailCCRecipient = Me.GetSetting("EmailCCRecipient")
			End If
			Return _emailCCRecipient
		End Get
	End Property
	Public ReadOnly Property EmailBCCRecipient() As PageModuleSetting
		Get
			If _emailBCCRecipient Is Nothing Then
				_emailBCCRecipient = Me.GetSetting("EmailBCCRecipient")
			End If
			Return _emailBCCRecipient
		End Get
	End Property
	Public ReadOnly Property EmailFromAddress() As PageModuleSetting
		Get
			If _emailFromAddress Is Nothing Then
				_emailFromAddress = Me.GetSetting("EmailFromAddress")
			End If
			Return _emailFromAddress
		End Get
	End Property
	Public ReadOnly Property EmailUserSubject() As PageModuleSetting
		Get
			If _emailUserSubject Is Nothing Then
				_emailUserSubject = Me.GetSetting("EmailUserSubject")
			End If
			Return _emailUserSubject
		End Get
	End Property
	Public ReadOnly Property EmailAdminSubject() As PageModuleSetting
		Get
			If _emailAdminSubject Is Nothing Then
				_emailAdminSubject = Me.GetSetting("EmailAdminSubject")
			End If
			Return _emailAdminSubject
		End Get
	End Property
	Public ReadOnly Property EventListingUrl() As PageModuleSetting
		Get
			If _eventListingUrl Is Nothing Then
				_eventListingUrl = Me.GetSetting("EventListingUrl")
			End If
			Return _eventListingUrl
		End Get
	End Property
	Public ReadOnly Property RedirectUrl() As PageModuleSetting
		Get
			If _redirectUrl Is Nothing Then
				_redirectUrl = Me.GetSetting("RedirectUrl")
			End If
			Return _redirectUrl
		End Get
	End Property

	Public ReadOnly Property ThankYouMessage() As HtmlContent
		Get
			Dim htmlContentId As Integer
			If _thankYouMessage Is Nothing Then
				Integer.TryParse(Me.ThankYouMessageHtmlContentIdSetting.SettingValue, htmlContentId)
				_thankYouMessage = New HtmlContent(Me.UserContext, htmlContentId)
				_thankYouMessage.Html = PortalHTML.ParseHTML(Me.PageModuleId, Me.CurrentPortal.UrlBase, _thankYouMessage.Html, Me.CurrentPortal.AppSettings.ApplicationMode)
			End If
			Return _thankYouMessage
		End Get
	End Property
	Public ReadOnly Property ThankYouMessageHtmlContentIdSetting() As PageModuleSetting
		Get
			If _thankYouMessageHtmlContentIdSetting Is Nothing Then
				_thankYouMessageHtmlContentIdSetting = Me.GetSetting("ThankYouMessageHtmlContentIdSetting")
			End If
			Return _thankYouMessageHtmlContentIdSetting
		End Get
	End Property
	Public ReadOnly Property AdminMessage() As HtmlContent
		Get
			Dim htmlContentId As Integer
			If _adminMessage Is Nothing Then
				Integer.TryParse(Me.AdminMessageHtmlContentIdSetting.SettingValue, htmlContentId)
				_adminMessage = New HtmlContent(Me.UserContext, htmlContentId)
				_adminMessage.Html = PortalHTML.ParseHTML(Me.PageModuleId, Me.CurrentPortal.UrlBase, _adminMessage.Html, Me.CurrentPortal.AppSettings.ApplicationMode)
			End If
			Return _adminMessage
		End Get
	End Property
	Public ReadOnly Property AdminMessageHtmlContentIdSetting() As PageModuleSetting
		Get
			If _adminMessageHtmlContentIdSetting Is Nothing Then
				_adminMessageHtmlContentIdSetting = Me.GetSetting("AdminMessageHtmlContentIdSetting")
			End If
			Return _adminMessageHtmlContentIdSetting
		End Get
	End Property

	Public ReadOnly Property DefaultState() As PageModuleSetting
		Get
			If _defaultState Is Nothing Then
				_defaultState = Me.GetSetting("DefaultState")
			End If
			Return _defaultState
		End Get
	End Property
	Public ReadOnly Property EventListingPageView() As PageView
		Get
			Dim pv As PageView = Nothing
			Dim pvId As Integer = 0
			Integer.TryParse(EventListingUrl.SettingValue, pvId)
			If pvId <> 0 Then
				pv = Me.CurrentPortal.FindPageView(pvId)
			End If
			Return pv
		End Get
	End Property
	Public ReadOnly Property RedirectPageView() As PageView
		Get
			Dim pv As PageView = Nothing
			Dim pvId As Integer = 0
			Integer.TryParse(RedirectUrl.SettingValue, pvId)
			If pvId <> 0 Then
				pv = Me.CurrentPortal.FindPageView(pvId)
			End If
			Return pv
		End Get
	End Property

	Protected Overrides Sub loadContent()
		Integer.TryParse(Request("EventDefinitionId"), Me.EntityId)
		If Me.EntityId <> Trabon.Global.INVALID_ID Then
			Me.EventDefinition = New EventDefinition(Me.EntityId, Me.UserContext)
			portalEventForm.Initialize(Me.EntityId)
			portalEventForm.LoadFormValues(Me.DefaultState.SettingValue, Me.EventListingPageView)
		Else
			'this will redirect the user back the event listing page if they somehow 
			'get to the RSVP page without a valid event definition id
			If Me.EventListingPageView IsNot Nothing Then
				Response.Redirect(Me.EventListingPageView.BuildUrl)
			End If
		End If
	End Sub

	Protected Sub tbtnSubmitForm_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles tbtnSubmitForm.Click
		processForm()
	End Sub
	Protected Sub btnCancel_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnCancel.Click
		Me.ReturnFromEditMode(False)
	End Sub
	Protected Sub btnSaveEmailSettings_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSaveEmailSettings.Click
		saveSettings()
	End Sub
	Protected Sub Page_SaveModuleState() Handles Me.SaveModuleState
		Me.pnlSettings.Visible = False
		Me.pnlRegistrant.Visible = False
		Me.pnlAdmin.Visible = False

		If Me.IsEditMode Then
			Select Case Me.rtsEventRSVPTabs.SelectedTab.Value
				Case "Settings"
					Me.pnlSettings.Visible = True
				Case "Registrant"
					Me.pnlRegistrant.Visible = True
				Case "Admin"
					Me.pnlAdmin.Visible = True
			End Select
		End If
	End Sub

	Private Sub processForm()
		Dim retVal As New ReturnValue
		retVal = portalEventForm.ProcessForm()
		If retVal.Success Then
			retVal = prepareEmail()
			If retVal.Success Then
				If Me.RedirectPageView IsNot Nothing Then
					If Me.RedirectPageView.Id <> Trabon.Global.INVALID_ID Then
						Response.Redirect(Me.RedirectPageView.BuildUrl)
					Else
						retVal.ErrorMessage = "The redirect page has no entry."
					End If
				End If
			End If
		End If
		If Not retVal.Success Then
			Me.AddMessage(retVal.ErrorMessage, Trabon.UI.NotificationMessageTypes.Error)
		End If
	End Sub
	Private Function prepareEmail() As ReturnValue
		Dim retVal As New ReturnValue
		Try
			portalEventForm.IsReadOnly = True
			Dim formDisplay As String = portalEventForm.Display()

			'user email
			If Not String.IsNullOrEmpty(portalEventForm.Registrant.Email) Then
				Dim userMessage As String = Me.ThankYouMessage.Html & "<br /><br />" & formDisplay
				retVal = sendNotification(portalEventForm.Registrant.Email, Me.EmailFromAddress.SettingValue, Me.EmailCCRecipient.SettingValue, Me.EmailBCCRecipient.SettingValue, Me.EmailUserSubject.SettingValue, userMessage)
			End If

			'admin email
			Dim adminMessage As String = Me.AdminMessage.Html & "<br /><br />" & formDisplay
			Dim eventOrganizerEmail = Me.EmailRecipient.SettingValue
			CurrentPortalSession.CurrentEventOrganizer = eventOrganizerEmail
			retVal = sendNotification(eventOrganizerEmail, Me.EmailFromAddress.SettingValue, Me.EmailCCRecipient.SettingValue, Me.EmailBCCRecipient.SettingValue, Me.EmailAdminSubject.SettingValue, adminMessage)
		Catch ex As Exception
			retVal.ErrorMessage = ex.Message.ToString
		End Try
		Return retVal
	End Function

	Private Function sendNotification(ByVal toList As String, ByVal fromAddress As String, ByVal ccList As String, ByVal bccList As String, ByVal subjectText As String, ByVal bodyText As String) As ReturnValue
		Dim retval As New ReturnValue
		Try
			Dim n As New Trabon.PortalFramework.Notification(Me.UserContext)
			n.IsHtml = True
			n.BodyHtml = bodyText
			n.Subject = subjectText
			n.FromAddress = fromAddress
			n.Recipients = toList
			n.CcRecipients = ccList
			n.BccRecipients = bccList
			n.SmtpHost = Me.CurrentPortal.ConfigSettings.EmailSettingsServerIPAddress
			retval.Success = n.SendEmail()
		Catch ex As Exception
			retval.ErrorMessage = ex.Message.ToString
		End Try
		Return retval
	End Function

	Protected Overrides Sub loadEditor()
		pnlDisplay.Visible = False
		pnlEdit.Visible = True

		Me.rtsEventRSVPTabs.SelectedIndex = 0

		Me.heAdminMessage.Editor.Height = 320
		Me.heAdminMessage.Editor.Width = 580
		Me.heThankYouMessage.Editor.Height = 320
		Me.heThankYouMessage.Editor.Width = 580

		Dim states As Generic.List(Of Trabon.CodeValue) = Me.PortalCodeSetManager.GetCodes(CodeSetManager.CachedCodeSet.StateCode, Me.PortalId)
		ListHelper.LoadList(ddlDefaultState, states, "CodeValueDisplay", "CodeValueId", Me.DefaultState.SettingValue, Nothing)

		loadPageViewList(Me.EventListingPageView, ddlEventListingPageViews)
		loadPageViewList(Me.RedirectPageView, ddlThankPageViews)

		txtRecipient.Text = Me.EmailRecipient.SettingValue
		txtCCRecipient.Text = Me.EmailCCRecipient.SettingValue
		txtBCCRecipient.Text = Me.EmailBCCRecipient.SettingValue
		txtFromAddress.Text = Me.EmailFromAddress.SettingValue
		txtUserSubject.Text = Me.EmailUserSubject.SettingValue
		txtAdminSubject.Text = Me.EmailAdminSubject.SettingValue

		'radThankYouMessage.Content = Me.ThankYouMessage.Html
		'radAdminMessage.Content = Me.AdminMessage.Html
		Me.heThankYouMessage.Initialize(Me.ThankYouMessage.Html)
		Me.heAdminMessage.Initialize(Me.AdminMessage.Html)
	End Sub
	Private Sub saveSettings()
		If Page.IsValid Then
			Me.EmailRecipient.SettingValue = txtRecipient.Text.Trim
			Me.EmailRecipient.Save()

			Me.EmailCCRecipient.SettingValue = txtCCRecipient.Text.Trim
			Me.EmailCCRecipient.Save()

			Me.EmailBCCRecipient.SettingValue = txtBCCRecipient.Text.Trim
			Me.EmailBCCRecipient.Save()

			Me.EmailFromAddress.SettingValue = txtFromAddress.Text.Trim
			Me.EmailFromAddress.Save()

			Me.EmailUserSubject.SettingValue = txtUserSubject.Text.Trim
			Me.EmailUserSubject.Save()

			Me.EmailAdminSubject.SettingValue = txtAdminSubject.Text.Trim
			Me.EmailAdminSubject.Save()

			Me.ThankYouMessage.Html = Me.heThankYouMessage.Content
			Me.ThankYouMessage.Save()
			If Me.ThankYouMessageHtmlContentIdSetting.PageModuleSettingId = Nothing Then
				Me.ThankYouMessageHtmlContentIdSetting.SettingValue = Me.ThankYouMessage.HtmlContentId.ToString
				Me.ThankYouMessageHtmlContentIdSetting.Save()
			End If

			Me.AdminMessage.Html = Me.heAdminMessage.Content
			Me.AdminMessage.Save()
			If Me.AdminMessageHtmlContentIdSetting.PageModuleSettingId = Nothing Then
				Me.AdminMessageHtmlContentIdSetting.SettingValue = Me.AdminMessage.HtmlContentId.ToString
				Me.AdminMessageHtmlContentIdSetting.Save()
			End If

			If ddlDefaultState.SelectedItem IsNot Nothing Then
				Me.DefaultState.SettingValue = ddlDefaultState.SelectedItem.Text
				Me.DefaultState.Save()
			End If

			If ddlEventListingPageViews.SelectedItem IsNot Nothing Then
				Me.EventListingUrl.SettingValue = ddlEventListingPageViews.SelectedItem.Value
				Me.EventListingUrl.Save()
			End If
			If ddlThankPageViews.SelectedItem IsNot Nothing Then
				Me.RedirectUrl.SettingValue = ddlThankPageViews.SelectedItem.Value
				Me.RedirectUrl.Save()
			End If
		End If
		Me.ReturnFromEditMode(False)
	End Sub
	Private Sub loadPageViewList(ByVal pv As PageView, ByVal ddl As DropDownList)
		If pv IsNot Nothing Then
			If pv.Id <> Trabon.Global.INVALID_ID Then
				ListHelper.LoadList(ddl, Me.CurrentPortal.GetPageViewList(Nothing), "Text", "Value", Nothing, Nothing, pv.Id)
				ddl.Items.Insert(0, " - None - ")
			Else
				ListHelper.LoadList(ddl, Me.CurrentPortal.GetPageViewList(Nothing), "Text", "Value", " - Select PageView - ", Nothing)
			End If
		Else
			ListHelper.LoadList(ddl, Me.CurrentPortal.GetPageViewList(Nothing), "Text", "Value", " - Select PageView - ", Nothing)
		End If
	End Sub

End Class