@echo off
rem
rem FILE: run-tests.bat
rem
rem ABSTRACT: Runs editorconfig test
rem

SETLOCAL ENABLEEXTENSIONS
set SCRIPT=%~0
set SCRIPT_FULLPATH=%~dpf0
set SCRIPTDRIVE=%~d0
set SCRIPTDIR=%~dp0
set SCRIPTDIR=%SCRIPTDIR:~0,-1%

set VIM_EXE_DIR=C:\Program Files\Vim\vim81

set LOG_DIR=%SCRIPTDIR%\logs
if NOT EXIST %LOG_DIR% (
    mkdir %LOG_DIR%
)

cd %SCRIPTDIR%

call :RunVim testset-editorconfig-core-filetree.vim      editorconfig-core-test\filetree
call :RunVim testset-editorconfig-core-glob.vim          editorconfig-core-test\glob
call :RunVim testset-editorconfig-core-parser.vim        editorconfig-core-test\parser
call :RunVim testset-editorconfig-core-properties.vim    editorconfig-core-test\properties
call :RunVim testset-editorconfig-plugin.vim             editorconfig-plugin-tests\test_files
call :RunVim testset-vim-extensions.vim                  vim_extension_tests

EXIT /B %ERRORLEVEL%

:RunVim
set TRF1=%~1
set TRF=%TRF1:~0,-4%
set TEST_RESULT_FILE=%LOG_DIR%\%TRF%.log
if EXIST %TEST_RESULT_FILE% (
    del %TEST_RESULT_FILE%
)
start "Vim" /w  "%VIM_EXE_DIR%\gvim.exe" --clean -u test_vimrc --noplugin -N -c "source %~1"
type %TEST_RESULT_FILE%

EXIT /B %ERRORLEVEL%



