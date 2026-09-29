@echo off
setlocal
set "CLI=C:\Users\Administrator\.vscode\extensions\anthropic.claude-code-2.1.280-win32-x64\resources\native-binary\claude.exe"
cd /d D:\projects\qwen3.8_fast\cc_test2
echo === auto-mode config ===
"%CLI%" auto-mode config > am_config.txt 2>&1
type am_config.txt
echo === debug run (auto-mode lines) ===
"%CLI%" --debug -p "say hi" > am_debug.txt 2>&1
findstr /i /c:"auto-mode" /c:"auto mode" /c:"isAutoMode" am_debug.txt
echo === end ===
