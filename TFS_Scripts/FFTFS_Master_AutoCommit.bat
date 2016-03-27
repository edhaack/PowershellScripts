@echo off

:: Master Batch for Auto Check-Ins / Commits for Family Features Websites
:: Created: 10/16/2012
::

::Constants
set ScriptsDir=I:\TFS_Scripts
::set LibrariesDir="I:\inetpub\Family Features\ffes-sites\Libraries"
set EditorsDir="I:\inetpub\Family Features\ffes-sites\ffes-editors"

:: Libraries Project
:: 10/16/12: Bob S. comment: Client should not be updating Libraries.
::call tfsAutoCommit %LibrariesDir% %ScriptsDir%

:: Editors Website
call tfsAutoCommit %EditorsDir% >> %ScriptsDir%\Output.log

