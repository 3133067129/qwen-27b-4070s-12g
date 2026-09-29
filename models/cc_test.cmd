@echo off
rem Run the Claude Code CLI that ships inside the VS Code extension, against the local engine.
setlocal
set "CLI=C:\Users\Administrator\.vscode\extensions\anthropic.claude-code-2.1.280-win32-x64\resources\native-binary\claude.exe"
set ANTHROPIC_BASE_URL=http://127.0.0.1:8099
set ANTHROPIC_AUTH_TOKEN=sk-local
set ANTHROPIC_MODEL=qwen3.8-27b
set ANTHROPIC_DEFAULT_SONNET_MODEL=qwen3.8-27b
set ANTHROPIC_DEFAULT_OPUS_MODEL=qwen3.8-27b
set ANTHROPIC_DEFAULT_HAIKU_MODEL=qwen3.8-27b
set CLAUDE_CODE_SUBAGENT_MODEL=qwen3.8-27b
set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
cd /d D:\projects\qwen3.8_fast\cc_test
"%CLI%" -p "Reply with exactly: HELLO" --model qwen3.8-27b > cc_out.txt 2>&1
echo CLAUDE_EXIT=%errorlevel%
type cc_out.txt
