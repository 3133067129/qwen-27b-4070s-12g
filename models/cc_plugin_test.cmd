@echo off
rem Exactly what the VS Code plugin does: no --settings flag, no model env vars -
rem Claude Code reads ~/.claude/settings.json only. Uses the native CLI from PATH.
setlocal
set "PATH=%USERPROFILE%\.local\bin;%PATH%"
set "PROJ=%~1"
set "TASK=%~2"
cd /d "%PROJ%"
claude --dangerously-skip-permissions -p "%TASK%" > plugin_out.txt 2>&1
echo CLAUDE_EXIT=%errorlevel%
type plugin_out.txt
