<%@ Control Language="VB" AutoEventWireup="false" CodeFile="EventList.ascx.vb" Inherits="Modules_App_Events_Display_EventList" %>
<div class="eventListing">
<asp:Repeater ID="rEvents" runat="server">
	<ItemTemplate>
		<table cellspacing="8" >
			<tr>
				<td colspan="2">
					<h2><asp:Label ID="lblEventTitle" runat="server" /></h2>
				</td>
			</tr>
			<tr>
				<td valign="top"><strong>Location</strong> &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </td>
				<td valign="top"><asp:Label ID="lblLocation" runat="server" /><br /><br /></td>
			</tr>
			
			<tr>
				<td valign="top"><strong>Details</strong></td>
				<td valign="top"><asp:Label ID="lblDetails" runat="server" /><br /><br /></td>
			</tr>
			<tr>
				<td valign="top"><strong>Times</strong></td>
				<td valign="top">
					<asp:Label ID="lblNoTime" runat="server" Visible="false">No times are available for this event.</asp:Label>
					<asp:Label ID="lblTimes" runat="server" />
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<p><asp:Hyperlink ID="lnkRsvpLink" runat="server">R.S.V.P. for this event.</asp:Hyperlink></p>
				</td>
			</tr>
		</table>
	</ItemTemplate>
	<SeparatorTemplate><hr /></SeparatorTemplate>
</asp:Repeater>
</div>