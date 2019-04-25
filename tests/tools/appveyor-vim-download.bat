@echo off
rem
rem File: vimdl.bat
rem
rem

SETLOCAL ENABLEEXTENSIONS
set SCRIPT=%~0
set SCRIPT_FULLPATH=%~dpf0
set SCRIPTDRIVE=%~d0
set SCRIPTDIR=%~dp0
set SCRIPTDIR=%SCRIPTDIR:~0,-1%


PATH=%PATH%;%userprofile%\local\curl-7.64.1-win64-mingw\bin

cd %temp%
if exist %temp%\vim rmdir /s /q %temp%\vim

rem Access "latest" release and interprete the Location header to get the current release version
curl -is https://github.com/vim/vim-win32-installer/releases/latest | findstr "Location:" > "%temp%\vim.loc"
set /p locHeader=<"%temp%\vim.loc"
for /f "tokens=*" %%I in ("%locHeader%") do for %%A in (%%~I) do set location=%%A
for /f "tokens=* delims=/" %%a in ("%location%") do set VERSIONSTR=%%~nxa
for /f "tokens=* delims=v" %%I in ("%VERSIONSTR%") do for %%A in (%%~I) do set VERSION=%%A
echo "VERSION: %VERSION%"

rem get version tag (<MAJOR><MINOR>)
for /F %%i in ("%VERSION%") do set MAINVERSION=%%~ni
for /F %%i in ("%MAINVERSION%") do set MAJOR=%%~ni
for /F %%i in ("%MAINVERSION%") do set MINOR=%%~xi
set MINOR=%MINOR:~1%
set VTAG=%MAJOR%%MINOR%


rem Download the current release as zip
set URL=https://github.com/vim/vim-win32-installer/releases/download/v%VERSION%/gvim_%VERSION%_x64.zip
curl -L -O %URL%
set ZIP=%temp%\gvim_%VERSION%_x64.zip

rem Extract the zip
7z x %zip% -o%temp%
rem powershell.exe -nologo -noprofile -command "& { $shell = New-Object -COM Shell.Application; $target = $shell.NameSpace('%temp%'); $zip = $shell.NameSpace('%ZIP%'); $target.CopyHere($zip.Items(), 16); }"

set VIM=%temp%\vim
set VIM_EXE_DIR=%temp%\vim\vim%VTAG%

echo set VIM=%temp%\vim>  "%temp%\VIM_ENV.bat"
echo set VIM_EXE_DIR=%temp%\vim\vim%VTAG%>> "%temp%\VIM_ENV.bat"

echo VIM dir: %VIM%
echo GVim exe dir: %VIM_EXE_DIR%



