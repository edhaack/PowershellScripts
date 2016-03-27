Option Strict On

Imports App

Partial Class Modules_App_Events_Editor_EventDetails : Inherits PortalApp.Base.PortalControl

   Private _entityId As Integer = Trabon.Global.INVALID_ID
   Private _eventDefinition As EventDefinition

   Public Event ReturnClick()
   Public Event NextClick(ByVal eventId As Integer)
   Public ValidationGroup As String = "EventFormValidation"

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
      Me.loadEventDefinition()

      Me.heLocation.Editor.Height = 240
      Me.heLocation.Editor.Width = 540
      Me.heDetails.Editor.Height = 240
      Me.heDetails.Editor.Width = 540

   End Sub
   Protected Sub btnNext_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnNext.Click
      saveEvent()
   End Sub
   Protected Sub lbtnBack_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lbtnBack.Click
      RaiseEvent ReturnClick()
   End Sub

   Private Sub loadEventDefinition()
      With Me.EventDefinition
         lblEventId.Text = .Id.ToString
         txtTitle.Text = .Title
         Me.heLocation.Initialize(.Location)
         Me.heDetails.Initialize(.Details)
      End With
   End Sub

   Private Sub retrieveFormValues()
      If Me.EventDefinitionId = Nothing Then
         Me.EventDefinition.PageModuleId = Me.ParentPortalModule.PageModuleId
      End If
      Me.EventDefinition.Title = txtTitle.Text.Trim
      Me.EventDefinition.Location = Me.heLocation.Content
      Me.EventDefinition.Details = Me.heDetails.Content
   End Sub
   Private Sub saveEvent()
      Dim success As Boolean = False

      If FormIsValid(ValidationGroup) Then

         Me.retrieveFormValues()

         Me.EventDefinition.Validate()
         If Me.EventDefinition.IsValid Then
            success = Me.EventDefinition.Save()
            Me.EventDefinitionId = Me.EventDefinition.Id
         End If

         If success Then
            RaiseEvent NextClick(Me.EventDefinitionId)
         Else
            For Each m As Trabon.Exceptions.ValidationException In Me.EventDefinition.ValidationExceptionsAll
               Me.AddMessage(m.Message.ToString, Trabon.UI.NotificationMessageTypes.Error)
            Next
         End If
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