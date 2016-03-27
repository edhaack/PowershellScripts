<%@ Control Language="VB" AutoEventWireup="false" CodeFile="EventDetails.ascx.vb" Inherits="Modules_App_Events_Editor_EventDetails" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Register TagPrefix="portal" TagName="HtmlEditor" Src="~/CommonControls/Standard/HtmlEditor/HtmlEditor.ascx" %>
<asp:LinkButton CssClass="ReturnLink" ID="lbtnBack" runat="server">Back to Events</asp:LinkButton>
<asp:ValidationSummary ID="RSVPFormValidationSummary" ValidationGroup="EventFormValidation" runat="server" CssClass="Warning" />
<asp:Label ID="lblEventId" runat="server" Visible="false" />
<table cellspacing="5">
   <tr>
      <td valign="top">
         <strong>Title</strong>
      </td>
      <td valign="top">
         <asp:TextBox ID="txtTitle" runat="server" Width="240" />
         <asp:RequiredFieldValidator ID="valTitle" ControlToValidate="txtTitle" ValidationGroup="EventFormValidation" runat="server" Display="Dynamic" ErrorMessage="You must enter a title for this Event.">*</asp:RequiredFieldValidator>
      </td>
   </tr>
   <tr>
      <td valign="top">
         <strong>Location</strong>
      </td>
      <td valign="top">
         <portal:HtmlEditor ID="heLocation" ShowCancelButton="false" ShowSaveButton="false" ShowEditLink="false" IsEditMode="true" runat="server" />
      </td>
   </tr>
   <tr>
      <td valign="top">
         <strong>Details</strong>
      </td>
      <td valign="top">
         <portal:HtmlEditor ID="heDetails" ShowCancelButton="false" ShowSaveButton="false" ShowEditLink="false" IsEditMode="true" runat="server" />
      </td>
   </tr>
</table>
<div class="EventButtons">
   <asp:Button ID="btnNext" Text="Next >" runat="server" />
</div>
