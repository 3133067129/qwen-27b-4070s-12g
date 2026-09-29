@echo off
rem Claude Code (extension binary) against the local engine, using a --settings file.
setlocal
set "CLI=C:\Users\Administrator\.vscode\extensions\anthropic.claude-code-2.1.280-win32-x64\resources\native-binary\claude.exe"
set "SETTINGS=D:\projects\qwen3.8_fast\models\cc_settings_test.json"
cd /d D:\projects\qwen3.8_fast\cc_test
"%CLI%" --settings "%SETTINGS%" -p "Reply with exactly: HELLO" > cc_out2.txt 2>&1
echo CLAUDE_EXIT=%errorlevel%
type cc_out2.txt
