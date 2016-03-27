<%@ Control Language="VB" AutoEventWireup="false" CodeFile="EventTimes.ascx.vb" Inherits="Modules_App_Events_Editor_EventTimes" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<div>
	<asp:LinkButton CssClass="ReturnLink" runat="server" ID="lbtnBack">Back to Event Details</asp:LinkButton>
	<asp:Label ID="lblEventId" runat="server" Visible="false" />
	<h2 style="margin-bottom:0;"><asp:Label ID="Title" runat="server" /></h2>
	<table>
		<tr>
			<td valign="top">
				&nbsp;
			</td>
			<td valign="top">
				<table>
					<tr>
						<td valign="top">
							<strong>Active Date</strong><br />
							<telerik:RadCalendar ID="activeDate" EnableMultiSelect="false" runat="server" Font-Names="Arial, Verdana, Tahoma"
								ForeColor="Black" Style="border-color: #ececec">
							</telerik:RadCalendar>
						</td>
						<td>
							&nbsp;&nbsp;&nbsp;&nbsp;
						</td>
						<td valign="top">
							<strong>Expire Date</strong><br />
							<telerik:RadCalendar ID="expireDate" EnableMultiSelect="false" runat="server" Font-Names="Arial, Verdana, Tahoma"
								ForeColor="Black" Style="border-color: #ececec">
							</telerik:RadCalendar>
					</tr>
					<tr>
						<td>&nbsp;</td>
						<td>&nbsp;</td>
						<td>
							<asp:RadioButtonList ID="expiration" runat="server">
								<asp:ListItem Text="Event expires" Value="Expire"/>
								<asp:ListItem Text="Event does not expire" Value="NoExpire"/>
							</asp:RadioButtonList>
						</td>
					</tr>
				</table>
			</td>
		</tr>
	</table>
	<div style="margin-top:-25px;">
		<p style="margin-bottom:0;"><strong>Times</strong></p>
		<asp:Label ID="noTime" runat="server" Visible="false"><p>No times are available for this event.</p></asp:Label>
		<asp:Repeater ID="rTimes" runat="server">
			<HeaderTemplate>
				<table cellspacing="10">
			</HeaderTemplate>
			<ItemTemplate>
				<tr>
					<td>
						<asp:Label ID="lblTime" runat="server" />
					</td>
					<td>
						<asp:Button ID="btnTimeEdit" runat="server" Text="Edit Time" />
					</td>
					<td>
						<asp:Button ID="btnTimeDelete" runat="server" Text="Remove Time" />
					</td>
				</tr>
			</ItemTemplate>
			<FooterTemplate>
				</table></FooterTemplate>
		</asp:Repeater>
	</div>
	<div>
		<p><asp:Button ID="btnCreateNewDateTime" runat="server" Text="Create New Date Time" /></p>
		<asp:Label ID="lblEditTime" runat="server" Visible="false"><p><strong>Edit Date / Time</strong></p></asp:Label>
		<asp:Label ID="lblNewTime" runat="server" Visible="false"><p><strong>Create New Date / Time</strong></p></asp:Label>
		<telerik:RadCalendar ID="newDate" runat="server" Visible="false" EnableMultiSelect="false"
			Font-Names="Arial, Verdana, Tahoma" 
			ForeColor="Black" 
			Style="border-color: #ececec">
		</telerik:RadCalendar>
		<telerik:RadTimePicker ID="newTime" runat="server" Visible="false" />
		<p><asp:Button ID="btnSaveNewDateTime" runat="server" Visible="false" Text="Save New Date Time" /></p>
		<p><asp:Button ID="btnUpdateDateTime" runat="server" Visible="false" Text="Save Date Time" /></p>
	</div>
</div>
<div class="EventButtons">
	<asp:Button ID="btnSubmit" runat="server" Text="Finish" />
</div>

<script type="text/javascript">
function ToggleDatePicker(enable){
	var calendar = document.getElementById('<%=expireDate.ClientID.ToString %>');
	if(enable){
		calendar.style.display = 'block';
	}else{
		calendar.style.display = 'none';		
	}
}
</script>