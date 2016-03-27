<%@ Control Language="VB" AutoEventWireup="false" CodeFile="Events.ascx.vb" Inherits="Modules_App_Events_Editor_Events" %>
<%@ Register TagPrefix="portal" TagName="EventDetails" Src="~/Modules/App/Events/Editor/EventDetails.ascx" %>
<%@ Register TagPrefix="portal" TagName="EventRegistrants" Src="~/Modules/App/Events/Editor/EventRegistrants.ascx" %>
<%@ Register TagPrefix="portal" TagName="EventTimes" Src="~/Modules/App/Events/Editor/EventTimes.ascx" %>
<%@ Register TagPrefix="portal" TagName="MessageCenter" Src="~/CommonControls/Standard/UI/MessageCenter.ascx" %>
<asp:Panel ID="pnlEventList" runat="server">                                                                            
   <asp:button ID="btnAddEvent" runat="server" Text="Add Event" />
   <portal:MessageCenter ID="mcEventMessages" CssClass="GlobalMessageCenter" MessageGroup="EventMessages" runat="server" />
   <br /><br />
   <asp:Label ID="noEvents" runat="server" Visible="false"><p>There are no available events.</p></asp:Label>
   <asp:Repeater ID="rptEvents" runat="server">
      <HeaderTemplate><div class="EventList"></HeaderTemplate>
      <ItemTemplate>
         <div class="EventItem">
            <div class="EventMenu">
               <asp:LinkButton ID="lbtnEditEvent" runat="server" >Edit Event</asp:LinkButton>
               <asp:LinkButton ID="lbtnArchiveEvent" runat="server" >Archive Event</asp:LinkButton>
               <asp:LinkButton ID="lbtnDeleteEvent" OnClientClick="return confirm('Are you sure you want to delete this event?');" runat="server">Delete Event</asp:LinkButton>
               <asp:LinkButton ID="lbtnViewRegistrants" runat="server" >View Registrants</asp:LinkButton>
            </div>
            <h2><asp:Label ID="lblEventTitle" runat="server" /></h2>
            <table>
               <tr>
                  <td valign="top" width="120"><strong>Location</strong></td>
                  <td valign="top"><asp:Label ID="lblLocation" runat="server" /></td>
               </tr>
               <tr>
                  <td valign="top"><strong>Details</strong></td>
                  <td valign="top"><asp:Label ID="lblDetails" runat="server" /></td>
               </tr>
               <tr>
                  <td valign="top"><strong>Times</strong></td>
                  <td valign="top"><asp:Label ID="lblTimes" runat="server" /></td>
               </tr>
            </table>
         </div>
      </ItemTemplate>
      <FooterTemplate></div></FooterTemplate>
   </asp:Repeater>
</asp:Panel>
<portal:EventDetails ID="portalEventDetails" runat="server" Visible="False" />
<portal:EventRegistrants ID="portalEventRegistrants" runat="server" Visible="False" />
<portal:EventTimes ID="portalEventTimes" runat="server" Visible="False" />






