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

	sIPList = "206.230.229.108" 'so we can refresh cache on other servers
	InitCatalog = "XcelWeb_Prod"
	InitCatalog_Report = "XcelReport"
	LoginDomain="Demo"
	SiteImage = "[path for site image - currently not in use]"
	ServerName = "db3\CDX,1705"
	ServerName_Report = "db3\CDX,1705"
	WebServerName = "demo.xceligent.com"
	WebServerNameDorey = "www.cie-gate.com"
	UploadServerName = "demo.xceligent.com"

	'make sure the path end with a backslash
	if instrrev(sDataFilePath,"\",len(sDataFilePath)) < len(sDataFilePath) then
		sDataFilePath = sDataFilePath & "\"
	end if

	'version
	AppVersion="7.0"
	JScriptVersion="7.0"
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
