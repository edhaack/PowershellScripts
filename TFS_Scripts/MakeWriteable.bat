@echo off
:: After TFS Setup, mark files in given directory as writable (not readonly)
:: Purpose: Check-In changes from prod (yes, they change prod directly), so that devs can get latest via VS.
:: Created: 2012.10.15
:: Updated: 

set localSiteDir=%1

:: This allows FTP users to rename/delete files and 'tfpt online' will pick up any adds/renames/deletes...
attrib -R "%localSiteDir%\*.*" /S /D
