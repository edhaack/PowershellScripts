dim desc, url
desc = WScript.Arguments.Item(0)
url = WScript.Arguments.Item(1)

set WshShell = WScript.CreateObject("WScript.Shell")
desktopFolder = WshShell.SpecialFolders("Desktop")
set link = WshShell.CreateShortcut(desktopFolder & "\" & desc & ".url")
link.TargetPath = url
link.Save
