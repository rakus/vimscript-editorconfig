@echo off
rem
rem FILE: run-tests.bat
rem
rem ABSTRACT: Runs editorconfig test
rem

rem SETLOCAL ENABLEEXTENSIONS
set SCRIPT=%~0
set SCRIPT_FULLPATH=%~dpf0
set SCRIPTDRIVE=%~d0
set SCRIPTDIR=%~dp0
set SCRIPTDIR=%SCRIPTDIR:~0,-1%

set VIM_EXE=gvim.exe
set NEOVIM_EXE=nvim-qt.exe
if NOT "X%APPVEYOR%" == "X" (
    if EXIST %temp%\VIM_ENV.bat (
        echo Calling %temp%\VIM_ENV.bat
        call %temp%\VIM_ENV.bat
    )
    if EXIST %temp%\NEOVIM_ENV.bat (
        echo Calling %temp%\VIM_ENV.bat
        call %temp%\NEOVIM_ENV.bat
    )
    echo VIM - %VIM%
    echo VIM_EXE_DIR - %VIM_EXE_DIR%
    set VIM_EXE=vim.exe
    set NEOVIM_EXE=nvim.exe
)


if "X%VIM_EXE_DIR%" == "X" (
    set VIM_EXE_DIR=C:\Program Files\Vim\vim81
)
if "X%NEOVIM_EXE_DIR%" == "X" (
    set NEOVIM_EXE_DIR=%userprofile%\local\Neovim\bin
)


set LOG_DIR=%SCRIPTDIR%\logs
if NOT EXIST %LOG_DIR% (
    mkdir %LOG_DIR%
)

set ORG_DIR=%cd%
cd %SCRIPTDIR%

set TEST_EXIT=0
if EXIST "%VIM_EXE_DIR%\%VIM_EXE%" (
    echo "Testing Vim (%VIM_EXE_DIR%\%VIM_EXE%)"
    call :RunVim testset-editorconfig-core-filetree.vim
    call :RunVim testset-editorconfig-core-glob.vim
    call :RunVim testset-editorconfig-core-parser.vim
    call :RunVim testset-editorconfig-core-properties.vim
    call :RunVim testset-editorconfig-plugin.vim
    call :RunVim testset-vim-extensions.vim
) else (
    echo "Vim not found (%VIM_EXE_DIR%\%VIM_EXE%)"
)
echo.
if EXIST "%NEOVIM_EXE_DIR%\%NEOVIM_EXE%" (
    echo "Testing NeoVim (%NEOVIM_EXE_DIR%\%NEOVIM_EXE%)"
    set VIM=
    call :RunNeoVim testset-editorconfig-core-filetree.vim
    call :RunNeoVim testset-editorconfig-core-glob.vim
    call :RunNeoVim testset-editorconfig-core-parser.vim
    call :RunNeoVim testset-editorconfig-core-properties.vim
    call :RunNeoVim testset-editorconfig-plugin.vim
    call :RunNeoVim testset-vim-extensions.vim
) else (
    echo "Neovim not found (%NEOVIM_EXE_DIR%\%NEOVIM_EXE%)"
)

echo.
if "%TEST_EXIT%" == "0" (
    echo SUCCESSFUL
) else (
    echo FAILED
)
cd %ORG_DIR%

EXIT /B %TEST_EXIT%

:RunVim
set TRF1=%~1
set TRF=%TRF1:~0,-4%
set TEST_RESULT_FILE=%LOG_DIR%\%TRF%.log
if EXIST %TEST_RESULT_FILE% (
    del %TEST_RESULT_FILE%
)
if "%VIM_EXE%" == "vim.exe" (
    "%VIM_EXE_DIR%\%VIM_EXE%" --clean -u test_vimrc --noplugin -N -c "source %~1" >NUL
    if errorlevel 1 set TEST_EXIT=1
) else (
    start "Vim" /w  "%VIM_EXE_DIR%\%VIM_EXE%" --clean -u test_vimrc --noplugin -N -c "source %~1"
    if errorlevel 1 set TEST_EXIT=1
)
type %TEST_RESULT_FILE%
EXIT /B %RC%

:RunNeoVim
set TRF1=%~1
set TRF=%TRF1:~0,-4%
set TEST_RESULT_FILE=%LOG_DIR%\%TRF%.log
if EXIST %TEST_RESULT_FILE% (
    del %TEST_RESULT_FILE%
)
if "%NEOVIM_EXE%" == "nvim.exe" (
    "%NEOVIM_EXE_DIR%\%NEOVIM_EXE%" --clean -u test_vimrc --noplugin -N -c "source %~1" >NUL
    if errorlevel 1 set TEST_EXIT=1
) else (
    start "NeoVim" /w  "%NEOVIM_EXE_DIR%\%NEOVIM_EXE%" -- --clean -u test_vimrc --noplugin -N -c "source %~1"
    if errorlevel 1 set TEST_EXIT=1
)
type %TEST_RESULT_FILE%
EXIT /B %ERRORLEVEL%


