@echo off
:: Simple Automated Script for FF:TFS
:: Purpose: Check-In changes from prod (yes, they change prod directly), so that devs can get latest via VS.
:: Created: 2012.10.15
:: Updated: 2012:10.15 - Adding comments...

:: Assumptions:
:: 1. The Project(s) are setup in TFS, and mapped to their working folders (and cloaked directories)
:: 2. 

set localSiteDir=%1
set comment="Check-in from FF Production"
set userCred=traboncompanies\fftfs,Debate12!
set excludedFileTypes=*.pdf,*.exe,*.scc,obj,_gsdata_,temp,*.bak*,*.bak,*.log,*.zip,*.pdb

::Gets any adds, updates, deletes, renames, etc. and marks them as ready for commit/check-in
tfpt online /adds /deletes /diff /noprompt /recursive /exclude:%excludedFileTypes% %localSiteDir%

::Standard checkin command - Should be checked in by specific user (needed)
tf checkin /recursive /noprompt /bypass /override:"Prod script" /comment:%comment% /login:%userCred% %localSiteDir% 

:: This allows FTP users to rename/delete files and 'tfpt online' will pick up any adds/renames/deletes...
attrib -R %localSiteDir%\*.* /S /D

