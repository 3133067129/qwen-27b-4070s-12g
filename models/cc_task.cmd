@echo off
rem Real agent task via the native CLI + the CC Switch provider "Bonsai 27B 本地 (NInfer)".
rem Usage: cc_task.cmd <project-dir> "<task>"
setlocal
set "PATH=%USERPROFILE%\.local\bin;%PATH%"
cd /d "%~1"
claude --dangerously-skip-permissions -p "%~2" > cc_task.txt 2>&1
echo CLAUDE_EXIT=%errorlevel%
type cc_task.txt
