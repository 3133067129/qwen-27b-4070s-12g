@echo off
set "CLI=C:\Users\Administrator\.vscode\extensions\anthropic.claude-code-2.1.280-win32-x64\resources\native-binary\claude.exe"
"%CLI%" install > D:\projects\qwen3.8_fast\models\claude_install.out 2>&1
echo INSTALL_EXIT=%errorlevel%
type D:\projects\qwen3.8_fast\models\claude_install.out
