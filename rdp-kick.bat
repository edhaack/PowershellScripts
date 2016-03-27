@echo off 
rem **************************************** 
rem Remote Desktop Protocol (RDP) Util - or
rem  or: "How to kick someone off an Remote Desktop Connection"
rem ****************************************

:help_requested 
if /I "%1" == "-?"     call :usage & exit /b 0 
if /I "%1" == "/?"     call :usage & exit /b 0 
if /I "%1" == "--help" call :usage & exit /b 0
if /I "%1" == "/help" call :usage & exit /b 0

rem :validate_args 
rem if "%1" == "" call :missing_arg & exit /b 1

:body 
set server=%1
if "%server%" == "" set /p server="Enter a server to query:" %=%
if "%server%" == "" exit :eof

query session /SERVER:%server%
set /p process="Enter the process id to logoff, and press [ENTER]. ["X": Quit]: " %=%
IF "%process%"=="X" goto :success
IF "%process%"=="x" goto :success

logoff %process% /server:%server%
query session /SERVER:%server%

echo Done.
goto :success

:success 
exit /b 0

:missing_arg 
    echo ERROR: One or more arguments are missing 
    echo. 
    call :usage 
goto :eof

:usage 
    echo USAGE: %~n0 [option ^| options...] 
    echo. 
    echo e.g. %~n0 xdwebtest
    echo. 
goto :eof