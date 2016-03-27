
'Get or Set current FF Host Filename
Set objShell = CreateObject("WScript.Shell")
Set objUser = objShell.Environment("User")

If objUser("CurrentFF") = "" then
	Wscript.Echo "Needs Creation"
	objUser("CurrentFF") = "Dev"
End If

dim SourceFile
dim DestinationFile
DestinationFile = "c:\windows\system32\drivers\etc\hosts"
if objUser("CurrentFF") = "Dev" then
	SourceFile = "c:\windows\system32\drivers\etc\hosts-FFProd"
	objUser("CurrentFF") = "Prod"
	MsgBox("Changing from Dev to Prod")
else
	SourceFile = "c:\windows\system32\drivers\etc\hosts-FFDev"
	objUser("CurrentFF") = "Dev"
	MsgBox("Changing from Prod to Dev")
end if

Set fso = CreateObject("Scripting.FileSystemObject")
    'Check to see if the file already exists in the destination folder
   If fso.FileExists(DestinationFile) Then
 '   	'Check to see if the file is read-only
   	If Not fso.GetFile(DestinationFile).Attributes And 1 Then 
   		'The file exists and is not read-only.  Safe to replace the file.
   		fso.CopyFile SourceFile, DestinationFile, True
   	Else 
   		'The file exists and is read-only.
   		'Remove the read-only attribute
 		fso.GetFile(DestinationFile).Attributes = fso.GetFile(DestinationFile).Attributes - 1
   		'Replace the file
   		fso.CopyFile SourceFile, DestinationFile, True
   		'Reapply the read-only attribute
   		fso.GetFile(DestinationFile).Attributes = fso.GetFile(DestinationFile).Attributes + 1
   	End If
   Else
   	'The file does not exist in the destination folder.  Safe to copy file to this folder.
   	fso.CopyFile SourceFile, DestinationFile, True
   End If
Set fso = Nothing
