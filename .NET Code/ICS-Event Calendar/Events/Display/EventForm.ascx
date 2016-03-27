<%@ Control Language="VB" AutoEventWireup="false" CodeFile="EventForm.ascx.vb" Inherits="Modules_App_Events_Email_EventForm" %>
<style>
	.required{color:Red;}
	.eventForm td{padding-top:2px;padding-right:5px;padding-bottom:2px;}
	.title{font-weight:bold;font-size:x-large;}
</style>
<asp:Label ID="lblEventDefinitionId" runat="server" visible="false" />
<asp:Label ID="lblRegistrationId" runat="server" visible="false" />
<table cellspacing="0" width="500">
	<tr>
		<td colspan="2" valign="top" align="right"><asp:Hyperlink ID="returnToEvents" runat="server">Return to event listing</asp:Hyperlink></td>
	</tr>
	<tr>
		<td colspan="2"><span class="title"><asp:Label ID="lblTitle" runat="server" /></span><br /><br /></td>
	</tr>
	<tr>
		<td valign="top" width="120"><strong>Location</strong></td>
		<td valign="top"><asp:Label ID="lblLocation" runat="server" /><br /><br /></td>
	</tr>
	<tr>
		<td valign="top" width="120"><strong>Details</strong></td>
		<td valign="top"><asp:Label ID="lblDetails" runat="server" /><br /><br /></td>
	</tr>
</table>
<asp:Panel ID="pnlInputForm" runat="server">
	<div id="contactform">
		 		<h4>Available Times:</h4>
	<fieldset class="checkboxes" style="padding-left:20px;">
			<asp:Label ID="noTime" runat="server" Visible="false"><p>No times are available for this event.</p></asp:Label>
			<asp:CheckBoxList CssClass="CheckBoxList" ID="chklstTimes" runat="server" />
		</fieldset>
				<asp:ValidationSummary ID="RSVPFormValidationSummary" CssClass="Warning" ValidationGroup="RSVPFormValidation" runat="server" Visible="False" />
		<br /><p><em>* Required Fields</em></p>
		<fieldset>
			<p><label for="FirstName">First Name*:</label><asp:TextBox ID="ttbFirstName" runat="server" Columns="30" MaxLength="50" /></p>
			<p><label for="LastName">Last Name*:</label><asp:TextBox ID="ttbLastName" runat="server" Columns="30" MaxLength="50" /></p>
			</fieldset>
			<fieldset>
			<p class="longinput"><label for="Address">Address*:</label><asp:TextBox ID="ttbAddress" runat="server" Columns="60" MaxLength="50" /></p>
			<p><label for="City">City*:</label><asp:TextBox ID="ttbCity" runat="server" Columns="30" MaxLength="50" /></p>
			<p><label for="State">State:</label><asp:DropDownList ID="ddlState" runat="server" /></p>
			<p id="zip"><label for="Zip">Zip*:</label><asp:TextBox ID="ttbZip" runat="server" Columns="10" MaxLength="20" /></p>
		</fieldset>
		<fieldset>
			<p><label for="Phone">Phone Number*:</label><asp:TextBox ID="ttbPhone" runat="server" Columns="30" MaxLength="50" /></p>
			<p><label for="Email">E-Mail Address*:</label><asp:TextBox ID="ttbEmail" runat="server" Columns="30" MaxLength="50" /></p>
		</fieldset>
		<fieldset>
			<p>Number of attendees</p>
<p>				<asp:DropDownList ID="ddlAttendees" runat="server" >
					<asp:ListItem>1</asp:ListItem>
					<asp:ListItem>2</asp:ListItem>
					<asp:ListItem>3</asp:ListItem>
					<asp:ListItem>4</asp:ListItem>
					<asp:ListItem>5</asp:ListItem>
					<asp:ListItem>6</asp:ListItem>
					<asp:ListItem>7</asp:ListItem>
					<asp:ListItem>8</asp:ListItem>
					<asp:ListItem>9</asp:ListItem>
					<asp:ListItem>10</asp:ListItem>
				</asp:DropDownList></p>
		</fieldset>
</div>

				<asp:RequiredFieldValidator runat="server" ID="valFirstName" ControlToValidate="ttbFirstName" Display="Dynamic" ValidationGroup="RSVPFormValidation" ErrorMessage="You must enter a first name.">*</asp:RequiredFieldValidator>
				<asp:RequiredFieldValidator runat="server" ID="valLastName" ControlToValidate="ttbLastName" Display="Dynamic" ValidationGroup="RSVPFormValidation" ErrorMessage="You must enter a last name.">*</asp:RequiredFieldValidator>
				<asp:RequiredFieldValidator runat="server" ID="valAddress" ControlToValidate="ttbAddress" Display="Dynamic" ValidationGroup="RSVPFormValidation" ErrorMessage="You must enter an address.">*</asp:RequiredFieldValidator>
				<asp:RequiredFieldValidator runat="server" ID="valCity" ControlToValidate="ttbCity" Display="Dynamic" ValidationGroup="RSVPFormValidation" ErrorMessage="You must enter a city." >*</asp:RequiredFieldValidator>
							<asp:RequiredFieldValidator runat="server" ID="valZip" ControlToValidate="ttbZip" Display="Dynamic" ValidationGroup="RSVPFormValidation" ErrorMessage="You must enter a zip code.">*</asp:RequiredFieldValidator>
				<asp:RegularExpressionValidator ID="valEmail" runat="server" ControlToValidate="ttbEmail" Display="Dynamic" ValidationGroup="RSVPFormValidation" ErrorMessage="Please enter a valid email address." Text="*" ValidationExpression=".*@.{2,}\..{2,}" >*</asp:RegularExpressionValidator>
</asp:Panel>
<asp:Panel ID="pnlOutputForm" runat="server" Visible="false">
	<br />
	<table cellspacing="0" width="500" class="eventForm">
		<tr>
			<td valign="top"><strong>Selected times:</strong></td>
			<td valign="top"><asp:Label ID="lblTimes" runat="server" /><br /><br /></td>
		</tr>
		<tr>
			<td valign="top">First Name</td>
			<td valign="top">
				<asp:Label ID="lblFirstName" runat="server" />
			</td>
		</tr>
		<tr>
			<td valign="top">Last Name</td>
			<td valign="top">
				<asp:Label ID="lblLastName" runat="server" />
			</td>
		</tr>
		<tr>
			<td valign="top">Address</td>
			<td valign="top">
				<asp:Label ID="lblAddress" runat="server" />
			</td>
		</tr>
		<tr>
			<td valign="top">City</td>
			<td valign="top">
				<asp:Label ID="lblCity" runat="server" />
			</td>
		</tr>
		<tr>
			<td valign="top">State</td>
			<td>
				<table>
					<tr>
						<td valign="top">
							<asp:Label ID="lblState" runat="server" />
						</td>
						<td valign="top">&nbsp;&nbsp;&nbsp;Zip</td>
						<td valign="top">
							<asp:Label ID="lblZip" runat="server" />
						</td>
					</tr>
				</table>
			</td>
		</tr>
		<tr>
			<td valign="top">Phone</td>
			<td valign="top">
				<asp:Label ID="lblPhone" runat="server" />
			</td>
		</tr>
		<tr>
			<td valign="top">Email</td>
			<td valign="top">
				<asp:Label ID="lblEmail" runat="server" />
			</td>
		</tr>
		<tr>
			<td valign="top">
				Number of attendees
			</td>
			<td valign="top">
				<asp:Label ID="lblAttendees" runat="server" />
			</td>
		</tr>
	</table>
</asp:Panel>