<#
Purpose: Script to update Web.config's 
Created: 2014.09 ESH

#>

<#  -- VARIABLES BEGIN -- #>
$startTime = Get-Date
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
#Set root level for path to make updates.

#Connection Strings... web.config files
#<add name="MainDB" connectionString="data source=xdvsqlm01\cdx,1705;initial catalog=XcelWeb_Prod;user=xceligentuser;password=xceligentuser"/>
#<add name="MainDB" connectionString="data source=xdsqltest\cdx,1705;initial catalog=XcelWeb_Prod;user=xceligentuser;password=xceligentuser"/>
#<add name="ReportDB" connectionString="data source=xdvsqlm01\cdx,1705;initial catalog=XcelWebReport_Prod;user=xceligentuser;password=xceligentuser"/>
#<add key="DB:MainDB" value="data source=xdvsqlm01\cdx,1705;initial catalog=XcelWeb_Prod;user=xceligentuser;password=xceligentuser"/>
#<add key="DB:MainDB" value="data source=xdsqltest\cdx,1705;initial catalog=XcelWeb_Prod;user=xceligentuser;password=xceligentuser"/>
#<add key="DB:ReportDB" value="data source=xdvsqlm01\cdx,1705;initial catalog=XcelWebReport_Prod;user=xceligentuser;password=xceligentuser"/>
#<value>data source=xdvsqlm01.xceligent.org\cdx,1705;initial catalog=CDXEPDShare;persist security info=True;user id=cdxEpdPub;password=jasWeyes38vu;multipleactiveresultsets=True;application name=CDXEPDSessionHelper</value>
#<add key="CDXDB" value="data source=xdvsqlm01\cdx,1705;initial catalog=XcelWeb_Prod;user=xceligentuser;password=xceligentuser"/>
#<add key="CDXDB2" value="data source=xdvsqlm01\cdx,1705;initial catalog=XcelWebReport_Prod;user=xceligentuser;password=xceligentuser"/>
#<add key="CDXODS" value="data source=xdvsqlm01\cdx,1705;initial catalog=ODS;user=xceligentuser;password=xceligentuser"/>

#XceligentApp: global_config.asp
#ServerName = "xdvsqlm01,1705\cdx"
#ServerName_Report = "xdvsqlm01,1705\cdx"

#XDVWEB01 (Server)
#CoreLogicService
#    <add name="CoreLogicPublic" providerName="System.Data.SqlClient"
#      connectionString="Server=db3.xceligent.com\cdx,1705;UID=web_services_user;PWD=D4yKYIy8cz9I1ehhk8SQ;database=ODS;"/>
#CountyDetailService
#    <add name="ODSPublic" providerName="System.Data.SqlClient"
#      connectionString="Server=db3.xceligent.com\cdx,1705;UID=web_services_user;PWD=D4yKYIy8cz9I1ehhk8SQ;database=ODS;"/>
#VT
#    <add name="XcelTCDataContextPrivate"
#      connectionString="metadata=res://TenantLib/EDMX.XcelTC.csdl|res://TenantLib/EDMX.XcelTC.ssdl|res://TenantLib/EDMX.XcelTC.msl;provider=System.Data.SqlClient;provider connection string=&quot;data source=xdvsqlm01.xceligent.org\cdx,1705\CDX;initial catalog=XcelWeb_Tenant;persist security info=True;user id=cdxEpdPvt;password=9e2uYequbruS;MultipleActiveResultSets=True;App=EntityFramework&quot;"
#      providerName="System.Data.EntityClient"/>
#    <add name="XcelTCDataContextPublic"
#     connectionString="metadata=res://TenantLib/EDMX.XcelTC.csdl|res://TenantLib/EDMX.XcelTC.ssdl|res://TenantLib/EDMX.XcelTC.msl;provider=System.Data.SqlClient;provider connection string=&quot;data source=xdvsqlm01.xceligent.org\cdx,1705\CDX;initial catalog=XcelWeb_Tenant;persist security info=True;user id=cdxEpdPub;password=jasWeyes38vu;MultipleActiveResultSets=True;App=EntityFramework&quot;"
#      providerName="System.Data.EntityClient"/>
#    <add name="CDXEPDShareDataContextPublic"
#      connectionString="metadata=res://CDXEPDShareLib/EDMX.CDXEPDShare.csdl|res://CDXEPDShareLib/EDMX.CDXEPDShare.ssdl|res://CDXEPDShareLib/EDMX.CDXEPDShare.msl;provider=System.Data.SqlClient;provider connection string=&quot;data source=xdvsqlm01.xceligent.org\cdx,1705\CDX;initial catalog=CDXEPDShare;persist security info=True;user id=cdxEpdPub;password=jasWeyes38vu;MultipleActiveResultSets=True;App=EntityFramework&quot;"
#      providerName="System.Data.EntityClient"/>

#<value>data source=xdvsqlm01.xceligent.org\cdx,1705;initial catalog=CDXEPDShare;persist security info=True;user id=cdxEpdPub;password=jasWeyes38vu;multipleactiveresultsets=True;application name=CDXEPDSessionHelper</value>
#<value>data source=xdvsqlm01.xceligent.org\cdx,1705;initial catalog=CDXEPDShare;persist security info=True;user id=cdxEpdPvt;password=9e2uYequbruS;multipleactiveresultsets=True;application name=CDXSessionLib</value>

#VTADMIN
#    <add name="XcelTCDataContextPrivate"
#      connectionString="metadata=res://*/EDMX.XcelTC.csdl|res://*/EDMX.XcelTC.ssdl|res://*/EDMX.XcelTC.msl;provider=System.Data.SqlClient;provider connection string=&quot;data source=xdvsqlm01.xceligent.org,1705;initial catalog=XcelWeb_Tenant;persist security info=True;user id=cdxEpdPvt;password=9e2uYequbruS;MultipleActiveResultSets=True;App=EntityFramework&quot;"
#      providerName="System.Data.EntityClient"/>
#    <add name="XcelTCDataContextPublic"
#      connectionString="metadata=res://*/EDMX.XcelTC.csdl|res://*/EDMX.XcelTC.ssdl|res://*/EDMX.XcelTC.msl;provider=System.Data.SqlClient;provider connection string=&quot;data source=xdvsqlm01.xceligent.org,1705;initial catalog=XcelWeb_Tenant;persist security info=True;user id=cdxEpdPub;password=jasWeyes38vu;MultipleActiveResultSets=True;App=EntityFramework&quot;"
#      providerName="System.Data.EntityClient"/>
#    <add name="ErrorLog" providerName="System.Data.SqlClient"
#      connectionString="server=xdvsqlm01.xceligent.org\CDX,1705;uid=web_services_user;pwd=D4yKYIy8cz9I1ehhk8SQ;database=AppLog;Connection Timeout=30;App=Elmah;"/>

#DriveTool 
#    <add name="ODSPublic" providerName="System.Data.SqlClient"
#      connectionString="Server=db3.xceligent.com\cdx,1705;UID=xceldbo;PWD=CSjNgjtycFQrvqBGct65;database=ODS;"/>
#    <add name="ResearchTrackerPublic" providerName="System.Data.SqlClient"
#      connectionString="Server=xdb2.xceligent.com\cdx,1705;UID=web_services_user;PWD=q463KeukLLOsZLUUG18T;database=ResearchTracker;"/>
#    <add name="XPRTPublic" providerName="System.Data.SqlClient"
#      connectionString="Server=xdvsqlm01.xceligent.org\cdx,1705;UID=xceldbo;PWD=ldFR7TLchIbKmyaUZQfn;database=XPRT;"/>
#    <add name="XCResearchPublic" providerName="System.Data.SqlClient"
#      connectionString="Server=xdvsqlm01.xceligent.org\cdx,1705;user=xceligentuser;password=xceligentuser;database=Xcelweb_Prod;Connection Timeout=60;"/>
#    <add name="XCResearchPrivate" providerName="System.Data.SqlClient"
#      connectionString="Server=xdvsqlm01.xceligent.org\cdx,1705;user=xceligentuser;password=xceligentuser;database=Xcelweb_Prod;Connection Timeout=60;"/>

<#  -- VARIABLES END -- #>

<#  -- FUNCTIONS BEGIN -- #>

#Checkout... Update file... Checkin...

<#  -- FUNCTIONS END -- #>

<#  -- MAIN BEGIN -- #>

#LOOP: Get all web.config files...

#Function to checkout, update and checkin...




<#  -- MAIN END -- #>

$endTime = Get-Date

$elapsedTime = $endTime - $startTime

"
Duration:
{0} minute(s) and {1} second(s)" -f $elapsedTime.Minutes, $elapsedTime.Seconds
"

Done.
" 

<#  --SCRIPT END-- #>