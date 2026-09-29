@echo off
rem Start the engine behind the Claude Code provider "Bonsai 27B 本地 (NInfer)" and wait
rem until it is ready (~85-110 s). Run this before opening Claude Code.
setlocal
set PORT=8099
tasklist /fi "imagename eq ninfer-serve.exe" 2>nul | find /i "ninfer-serve.exe" >nul
if not errorlevel 1 (
  echo engine already running on port %PORT%
  exit /b 0
)
echo starting Bonsai 27B ternary for Claude Code (MTP K=3, 64k context) ...
start "ninfer-claude" /min "%~dp0claude_serve_inner.cmd"
for /l %%i in (1,1,60) do (
  ping -n 6 127.0.0.1 >nul 2>&1
  curl.exe -s -f -o nul http://127.0.0.1:%PORT%/v1/models
  if not errorlevel 1 (
    echo engine ready - Claude Code can use "Bonsai 27B local (NInfer)" now
    exit /b 0
  )
)
echo FAILED to start, last log lines:
type "D:\projects\qwen3.8_fast\models\claude_serve.log" 2>nul
exit /b 1
