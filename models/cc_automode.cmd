@echo off
setlocal
set "CLI=C:\Users\Administrator\.vscode\extensions\anthropic.claude-code-2.1.280-win32-x64\resources\native-binary\claude.exe"
cd /d D:\projects\qwen3.8_fast\cc_test2
echo === claude auto-mode ===
"%CLI%" auto-mode > am_inspect.txt 2>&1
echo inspect_exit=%errorlevel%
type am_inspect.txt
echo === permission-mode auto (headless) ===
"%CLI%" --permission-mode auto -p "Reply with exactly: AUTOOK" > am_run.txt 2>&1
echo auto_exit=%errorlevel%
type am_run.txt
