Dim IIsObject
Set IIsObject = GetObject ("IIS://localhost/w3svc")
WScript.Echo "According to the metabase, the anonymous credentials are:"
WScript.Echo "    AnonymousUserName = " & IIsObject.Get("AnonymousUserName")
WScript.Echo "    AnonymousUserPass = " & IIsObject.Get("AnonymousUserPass")
WScript.Echo "    WAMUserName = " & IIsObject.Get("WAMUserName")
WScript.Echo "    WAMUserPass = " & IIsObject.Get("WAMUserPass")
Set IIsObject = Nothing