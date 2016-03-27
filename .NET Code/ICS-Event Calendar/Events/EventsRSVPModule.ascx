<%@ Control Language="VB" AutoEventWireup="false" CodeFile="EventsRSVPModule.ascx.vb" Inherits="Modules_App_Events_EventsRSVPModule" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Register TagPrefix="portal" TagName="EventForm" Src="~/Modules/App/Events/Display/EventForm.ascx" %>
<%@ Register TagPrefix="portal" TagName="HtmlEditor" Src="~/CommonControls/Standard/HtmlEditor/HtmlEditor.ascx" %>
<asp:Panel ID="pnlDisplay" class="contactForm" runat="server">
   <portal:EventForm ID="portalEventForm" runat="server" />
   <trabon:TrabonButton ID="tbtnSubmitForm" Text="Submit" runat="server" />
</asp:Panel>
<asp:Panel ID="pnlEdit" CssClass="EventsEditor" Visible="false" runat="server">     
   <telerik:RadTabStrip ID="rtsEventRSVPTabs" Skin="Default" AutoPostBack="true" PerTabScrolling="true" runat="server">
      <Tabs>
         <telerik:RadTab Text="Email Settings" Value="Settings">
         </telerik:RadTab>
         <telerik:RadTab Text="Registrant Message" Value="Registrant">
         </telerik:RadTab>
         <telerik:RadTab Text="Admin Message" Value="Admin">
         </telerik:RadTab>
      </Tabs>
   </telerik:RadTabStrip>
   <div class="TabContentTop">
   </div>
   <asp:Panel ID="pnlTabContent" CssClass="TabContent" Style="width: 600px; min-height: 320px; overflow: hidden;" runat="server">
      <asp:Panel ID="pnlSettings" runat="server">
         <table cellpadding="0" cellspacing="5">
            <tr>
               <td>
                  Event Listing Page:
               </td>
               <td>
                  <asp:DropDownList ID="ddlEventListingPageViews" runat="server" />
               </td>
            </tr>
            <tr>
               <td>
                  Thank you page:
               </td>
               <td>
                  <asp:DropDownList ID="ddlThankPageViews" runat="server" />
               </td>
            </tr>
            <tr>
               <td>
                  Email Recipient:
               </td>
               <td>
                  <asp:TextBox ID="txtRecipient" runat="server" />
                  <asp:RegularExpressionValidator ID="valEmailRecipientReg" runat="server" Text="*" ErrorMessage="Please enter a valid email address." ValidationExpression=".*@.{2,}\..{2,}" ControlToValidate="txtRecipient" />
               </td>
            </tr>
            <tr>
               <td>
                  Email CC Recipient:
               </td>
               <td>
                  <asp:TextBox ID="txtCCRecipient" runat="server" />
                  <asp:RegularExpressionValidator ID="valEmailCCRecipientReg" runat="server" Text="*" ErrorMessage="Please enter a valid email address." ValidationExpression=".*@.{2,}\..{2,}" ControlToValidate="txtCCRecipient" />
               </td>
            </tr>
            <tr>
               <td>
                  Email BCC Recipient:
               </td>
               <td>
                  <asp:TextBox ID="txtBCCRecipient" runat="server" />
                  <asp:RegularExpressionValidator ID="valEmailBCCRecipientReg" runat="server" Text="*" ErrorMessage="Please enter a valid email address." ValidationExpression=".*@.{2,}\..{2,}" ControlToValidate="txtBCCRecipient" />
               </td>
            </tr>
            <tr>
               <td>
                  Email From Address:
               </td>
               <td>
                  <asp:TextBox ID="txtFromAddress" runat="server" />
                  <asp:RegularExpressionValidator ID="valEmailFromAddressReg" runat="server" Text="*" ErrorMessage="Please enter a valid email address." ValidationExpression=".*@.{2,}\..{2,}" ControlToValidate="txtFromAddress" />
               </td>
            </tr>
            <tr>
               <td>
                  Email User Subject:
               </td>
               <td>
                  <asp:TextBox ID="txtUserSubject" runat="server" />
               </td>
            </tr>
            <tr>
               <td>
                  Email Admin Subject:
               </td>
               <td>
                  <asp:TextBox ID="txtAdminSubject" runat="server" />
               </td>
            </tr>
            <tr>
               <td>
                  Default State:
               </td>
               <td>
                  <asp:DropDownList ID="ddlDefaultState" runat="server" />
               </td>
            </tr>
         </table>
      </asp:Panel>
      <asp:Panel ID="pnlRegistrant" runat="server">
         Thank you message (for the user):<br /><br />
         <portal:HtmlEditor ID="heThankYouMessage" ShowCancelButton="false" ShowSaveButton="false" ShowEditLink="false" IsEditMode="true" runat="server" />
      </asp:Panel>
      <asp:Panel ID="pnlAdmin" runat="server">
         New contact message (for the site administrator):<br /><br />
         <portal:HtmlEditor ID="heAdminMessage" ShowCancelButton="false" ShowSaveButton="false" ShowEditLink="false" IsEditMode="true" runat="server" />
      </asp:Panel>
      <div class="EventButtons">
         <asp:Button runat="server" ID="btnSaveEmailSettings" Text="Save Settings" />&nbsp;
         <asp:Button runat="server" ID="btnCancel" Text="Cancel" />
      </div>
   </asp:Panel>
</asp:Panel>
