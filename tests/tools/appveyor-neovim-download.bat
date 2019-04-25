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
if exist %temp%\Neovim rmdir /s /q %temp%\Neovim

rem Download Neovim Nightly build
set URL=https://github.com/neovim/neovim/releases/download/nightly/nvim-win64.zip
curl -L -O %URL%
set ZIP=%temp%\nvim-win64.zip

rem Extract the zip
7z x %zip% -o%temp%

echo set NEOVIM_EXE_DIR=%temp%\Neovim\bin>> "%temp%\NEOVIM_ENV.bat"

