Imports App
Imports System.Globalization

Partial Class Modules_App_Events_EventsRSVPiCalendarModule
	Inherits PortalApp.Base.PortalModuleControl

	Private _eventTimes As List(Of EventTime)
	Private _eventDefinition as EventDefinition

	Private Const IceFilenameStructure = "Edgehill - {0}.ics"
	Private Const HtmlDescTemplate = "<!DOCTYPE HTML PUBLIC ""-//W3C//DTD HTML 3.2//EN"">\n<HTML>\n<HEAD>\n<META NAME=""Generator"" CONTENT=""MS Exchange Server version 08.00.0681.000"">\n<TITLE></TITLE>\n</HEAD>\n<BODY>\n{0}\n</BODY>\n</HTML>"
	Private const NewLineCharacter as String = "\n"

	''' <summary>
	''' Raises the <see cref="E:System.Web.UI.Control.Load"/> reg.
	''' </summary>
	''' <param name="e">The <see cref="T:System.EventArgs"/> object that contains the reg data. 
	''' </param>
	Protected Overrides Sub OnLoad(ByVal e As EventArgs)
		MyBase.OnLoad(e)

		'Get Id from session... if nothing then don't show the links to download...
		_eventTimes = CurrentPortalSession.EventTimes

		If (_eventTimes.Count < 1) Then
			btnICSDownload.Visible = False
			Return
		End If

	End Sub

	Protected Sub HandleDownloadClick(ByVal sender As Object, ByVal e As EventArgs)
		_eventDefinition = CurrentPortalSession.CurrentEventDefinition
		Dim icsFile = BuildICalendarContent()
		Dim icsFileName = String.Format(IceFilenameStructure, _eventDefinition.Title)
		PushFileToClient(IcsFilename, icsFile)
	End Sub

	Private Function BuildICalendarContent() As String
		Dim eventTimeDuration = CurrentPortal.AppSettings.DefaultEventTimeDuration
		Dim eventOrganizer = CurrentPortalSession.CurrentEventOrganizer
		Dim eventUrl = CurrentPortalSession.CurrentEventUrl
		Return GetIcs(_eventTimes, eventTimeDuration, eventOrganizer, eventUrl)
	End Function

	Private Function GetIcs(ByVal eventTimes As List(Of EventTime), ByVal eventTimeDuration As Double, ByVal eventOrganizer As String, ByVal eventUrl As String) As String
		Dim organizer = String.Format("ORGANIZER;SENT-BY=""MAILTO:{0}"":MAILTO:{0}", eventOrganizer)
		Dim summary = ClenseHtml(_eventDefinition.Title)
		Dim location = ClenseHtml(_eventDefinition.Location)
		Dim cleanDetails = _eventDefinition.Details
		Dim description = String.Format("{0}{1}{1}Link to Event:{1}{2}{1}", ClenseHtml(cleanDetails), NewLineCharacter, eventUrl)
		Dim details = String.Format("{0}<br/><br/><a href=""{1}"">View Event Page</a><br/><br/>", _eventDefinition.Details, eventUrl)
		Dim htmlDescription = String.Format(HtmlDescTemplate, details)

		Dim endDateTime As Date
		Dim ics = New StringBuilder()
		ics.Append("BEGIN:VCALENDAR" + vbCrLf)
		ics.Append("VERSION:2.0" + vbCrLf)
		ics.Append("PRODID:-//EdgehillCommuniity/Events Calendar//EN" + vbCrLf)
		For Each eventTime In eventTimes
			endDateTime = eventTime.Time.AddHours(eventTimeDuration)
			ics.Append("BEGIN:VEVENT" + vbCrLf)
			ics.Append("UID:" + Guid.NewGuid().ToString() + vbCrLf)
			ics.Append("DTSTAMP:" & eventTime.Time.ToUniversalTime().ToString("yyyyMMddTHHmmssZ") & vbCrLf)
			ics.Append("DTSTART:" & eventTime.Time.ToUniversalTime().ToString("yyyyMMddTHHmmssZ") & vbCrLf)
			ics.Append("DTEND:" & endDateTime.ToUniversalTime().ToString("yyyyMMddTHHmmssZ") & vbCrLf)
			ics.Append("SEQUENCE:0" & vbCrLf)
			ics.Append("STATUS:CONFIRMED" & vbCrLf)
			ics.Append(organizer & vbCrLf)
			ics.Append("LOCATION:" & location & vbCrLf)
			ics.Append("DESCRIPTION:" & description & vbCrLf)
			ics.Append("X-ALT-DESC;FMTTYPE=text/html:" & htmlDescription & vbCrLf)
			ics.Append("SUMMARY:" & summary & vbCrLf)
			ics.Append("CLASS:PUBLIC" & vbCrLf)
			ics.Append("TRANSP:OPAQUE" & vbCrLf)
			ics.Append("END:VEVENT" & vbCrLf)
		Next
		ics.Append("END:VCALENDAR" + vbCrLf)
		Return ics.ToString()
	End Function

	Private Shared Function ClenseHtml(ByVal content As String) As String
		dim rawContent = content
		'Replace br tags with line breaks
		Dim cleanContent = rawContent.Replace("<br>", NewLineCharacter)
		cleanContent = cleanContent.Replace("<br/>", NewLineCharacter)
		cleanContent = cleanContent.Replace("<br />", NewLineCharacter)
		cleanContent = cleanContent.Replace("<BR>", NewLineCharacter)
		cleanContent = cleanContent.Replace("<BR/>", NewLineCharacter)
		cleanContent = cleanContent.Replace("<BR />", NewLineCharacter)
		cleanContent = Regex.Replace(cleanContent, "<.*?>", "")
		Return cleanContent
	End Function

	Private Shared Sub PushFileToClient(ByVal filename As String, ByVal fileContents As String)
		Dim response = HttpContext.Current.Response
		response.Clear()
		response.ClearContent()
		response.ClearHeaders()
		response.ContentType = "text/calendar"
		response.ContentEncoding = Encoding.UTF8
		response.Charset = "utf-8"
		response.AddHeader("Content-Disposition", String.Format("attachment; filename=""{0}""", filename))
		response.AddHeader("Content-Length", fileContents.Length.ToString(CultureInfo.InvariantCulture))
		response.Write(fileContents)
		response.End()
	End Sub

End Class
