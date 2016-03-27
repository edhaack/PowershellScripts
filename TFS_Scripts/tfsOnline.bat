@echo off

set localSiteDir="I:\inetpub\Family Features\ffes-sites\ffes-editors"
set comment="Check-in from FF Production"

::Gets any adds, updates, deletes, renames, etc. and marks them as ready for commit/check-in
tfpt online /adds /deletes /diff /noprompt /recursive %localSiteDir%

echo Exit Code is %errorlevel%