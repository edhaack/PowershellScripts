<SCRIPT LANGUAGE='VBScript' RUNAT='Server'>
Dim LoginDomain
Dim SiteImage
Dim InitCatalog,InitCatalog_Report
Dim ServerName, ServerName_Report
Dim UserName,Password,UserName_Report,Password_Report
Dim blnInHouse,blnCacheTemplates,blnUseCaching
dim DisabledColor
dim WebServerName,WebServerNameDorey
dim sDataFilePath,sChangeLogPath
dim sIPList
dim AppVersion, JScriptVersion
dim XMailText, XMailColorText
dim CS_Link


sub InitConfig

	'this controls where the lookup table data files are written to and read from
	sDataFilePath = server.MapPath("/xceligentdata/")

	'this controls where the change log data files are written to
	sChangeLogPath = server.MapPath("/ChangeLog/")

	sIPList = "206.230.229.121;206.230.229.122;206.230.229.123;206.230.229.124" 'so we can refresh cache on other servers
	InitCatalog = "XcelWeb_Prod"
	InitCatalog_Report = "xcelWebReport_Prod"
	LoginDomain="Production"
	SiteImage = "[path for site image - currently not in use]"
	ServerName = "SQLM01Prod,1705"
	ServerName_Report = "SQLM02Prod,1705"
	WebServerName = "cdxairtest.xceligent.com"
	WebServerNameDorey = "www.cie-gate.com"
	UploadServerName = "cdxairtest.xceligent.com"
	'make sure the path end with a backslash
	if instrrev(sDataFilePath,"\",len(sDataFilePath)) < len(sDataFilePath) then
		sDataFilePath = sDataFilePath & "\"
	end if

	'version
	AppVersion="8.4.2"
	JScriptVersion="8.4.2"
	blnInHouse = false
	blnCacheTemplates=false
	blnUseCaching = false

	DisabledColor = "#cccccc"

	UserName="xceligentuser"
	Password="xceligentuser"

	UserName_Report="xceligentuser"
	Password_Report="xceligentuser"

	UserName_Internal="xceligentinternal"
	Password_Internal="xceligentinternal"

	XMailText="CDXMail"
	XMailColorText="<font color='5A86C4'><b>CDX</b></font>Mail"
	CS_Link = "http://www.ccienet.com/sh/asp/remLogin.aspx?mkt=co"


end sub

</Script>
