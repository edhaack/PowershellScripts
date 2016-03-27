<%@ Control Language="VB" AutoEventWireup="false" CodeFile="EventRegistrants.ascx.vb" Inherits="Modules_App_Events_Editor_EventRegistrants" %>
<asp:LinkButton CssClass="ReturnLink" ID="lbtnBack" runat="server">Back to Events</asp:LinkButton>
<asp:Panel ID="pnlEventDetails" CssClass="EventItem" Style="margin-top: 10px;" runat="server">
   <asp:Label ID="lblEventId" runat="server" Visible="false" />
   <h2>
      <asp:Label ID="Title" runat="server" /></h2>
   <table>
      <tr>
         <td valign="top">
            <strong>Location</strong>
         </td>
         <td valign="top">
            <asp:Label ID="lblLocation" runat="server" />
         </td>
      </tr>
      <tr>
         <td valign="top">
            <strong>Details</strong>
         </td>
         <td valign="top">
            <asp:Label ID="lblDetails" runat="server" />
         </td>
      </tr>
      <tr>
         <td valign="top">
            <strong>Times:</strong>
         </td>
         <td valign="top">
            <asp:Label ID="lblTimes" runat="server" />
         </td>
      </tr>
   </table>
</asp:Panel>
<div runat="server">
   <h2 style="float: left;">
      Registrants:</h2>
   <asp:Button ID="btnSaveToExcel" Text="Save to Excel" Style="float: right;" runat="server" />
   <telerik:RadGrid ID="grdEventRegistrants" Skin="Default" AllowPaging="True" AllowSorting="True" AutoGenerateColumns="False" EnableAjax="True" Style="clear: both;" runat="server">
      <MasterTableView ItemStyle-VerticalAlign="Top" AlternatingItemStyle-VerticalAlign="Top">
         <Columns>
            <telerik:GridTemplateColumn HeaderText="Name">
               <ItemTemplate>
                  <%# Eval("FirstName") %>&nbsp;<%# Eval("LastName") %>
               </ItemTemplate>
            </telerik:GridTemplateColumn>
            <telerik:GridTemplateColumn HeaderText="Address">
               <ItemTemplate>
                  <%# Eval("Address")%><br />
                  <%# Eval("City")%>,
                  <%# Eval("State")%>
                  <%# Eval("Zip")%>
               </ItemTemplate>
            </telerik:GridTemplateColumn>
            <telerik:GridBoundColumn HeaderText="Phone" DataField="Phone" />
            <telerik:GridBoundColumn HeaderText="Email" DataField="Email" />
            <telerik:GridBoundColumn HeaderText="Persons" DataField="AttendeeCount" />
            <telerik:GridBoundColumn HeaderText="Date" DataField="CreatedDtTm" DataFormatString="{0:d}" />
         </Columns>
      </MasterTableView>
   </telerik:RadGrid>
</div>
