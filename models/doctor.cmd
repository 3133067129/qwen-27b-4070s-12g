@echo off
rem Health check of the native Claude Code install.
setlocal
set "PATH=%USERPROFILE%\.local\bin;%PATH%"
if "%~1"=="" (cd /d D:\projects\qwen3.8_fast\cc_test2) else (cd /d "%~1")
claude doctor
