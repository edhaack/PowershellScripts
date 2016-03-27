<%@ Control Language="VB" AutoEventWireup="false" CodeFile="EventModuleSettings.ascx.vb" Inherits="Modules_App_Events_Editor_EventModuleSettings" %>
<table cellpadding="0" cellspacing="0">
   <tr>
      <td class="Label">
         RSVP page:
      </td>
      <td class="Value">
         <asp:DropDownList ID="ddlRSVPPageViews" runat="server" />
      </td>
   </tr>
</table>
<div class="EventButtons">
   <asp:Button ID="btnSaveSettings" Text="Save Settings" CssClass="StandardButton" runat="server" />
</div>
