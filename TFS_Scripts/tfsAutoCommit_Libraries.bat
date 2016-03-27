@echo off
:: Simple Automated Script for FF:TFS
:: Purpose: Check-In changes from prod (yes, they change prod directly), so that devs can get latest via VS.
:: Created: 2012.10.15
:: Updated: 

set localSiteDir="I:\inetpub\Family Features\ffes-sites\Libraries"
set comment="Check-in from FF Production"

tfpt online /adds /deletes /diff /noprompt /recursive %localSiteDir%
tf checkin /recursive /noprompt /bypass /override:"Prod script" /comment:%comment% /login:traboncompanies\fftfs,Debate12! %localSiteDir% 
::tf checkin /recursive /noprompt /bypass /override:"Prod script" /comment:%comment% %localSiteDir%
::tf checkin /recursive /noprompt /bypass /override:"Prod script" /comment:"Check-in from FF Production" /login:tfstrabon\fftfs,Debate12!  I:\TFSTest\ffes-sites\ffes-editors

:: This allows FTP users to rename/delete files and 'tfpt online' will pick up any adds/renames/deletes...
cd %localSiteDir%
attrib -R "*.*" /S /D

