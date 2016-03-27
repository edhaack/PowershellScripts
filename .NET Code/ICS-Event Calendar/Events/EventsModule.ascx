<%@ Control Language="VB" AutoEventWireup="false" CodeFile="EventsModule.ascx.vb" Inherits="Modules_App_Events_EventsModule" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Register TagPrefix="portal" TagName="EventList" Src="~/Modules/App/Events/Display/EventList.ascx" %>
<%@ Register TagPrefix="portal" TagName="EventEditor" Src="~/Modules/App/Events/Editor/Events.ascx" %>
<%@ Register TagPrefix="portal" TagName="EventModuleSettings" Src="~/Modules/App/Events/Editor/EventModuleSettings.ascx" %>
<%@ Register TagPrefix="portal" TagName="EventModuleInstructions" Src="~/Modules/App/Events/SetupInstructions/SetupInstructions.ascx" %>
<asp:Panel ID="pnlDisplay" CssClass="EventsList" runat="server">
   <portal:EventList ID="portalEventList" runat="server" />
</asp:Panel>
<asp:Panel ID="pnlEdit" CssClass="EventsEditor" runat="server" Visible="false">
   <asp:LinkButton ID="btnReturn" Text="Close" CssClass="ReturnLink" style="top: 20px; right: 20px;" runat="server"></asp:LinkButton>
   <telerik:RadTabStrip ID="rtsEventTabs" Skin="Default" AutoPostBack="true" PerTabScrolling="true" runat="server">
      <Tabs>
         <telerik:RadTab Text="Manage Events" Value="Manage">
         </telerik:RadTab>
         <telerik:RadTab Text="Module Settings" Value="ModuleSettings">
         </telerik:RadTab>
         <telerik:RadTab Text="Archived Events" Value="Archived">
         </telerik:RadTab>
         <telerik:RadTab Text="Setup Instructions" Value="Instructions">
         </telerik:RadTab>
      </Tabs>
   </telerik:RadTabStrip>
   <div class="TabContentTop">
   </div>
   <asp:Panel ID="pnlTabContent" CssClass="TabContent" Style="width: 600px; min-height: 320px; overflow: hidden;" runat="server">
      <portal:EventEditor ID="portalEventEditor" runat="server" />
      <portal:EventModuleSettings ID="portalEventModuleSettings" runat="server" />
      <portal:EventModuleInstructions ID="portalEventModuleInstructions" runat="server" />
   </asp:Panel>
</asp:Panel>
