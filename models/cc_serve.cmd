@echo off
rem Engine configuration used for the Claude Code integration test.
rem  %1 = context (default 16384)   %2 = kv dtype (default fp8)   %3 = spec (dflash2|mtp)
setlocal
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
set ART=D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer
set CTX=%1
if "%CTX%"=="" set CTX=16384
set KV=%2
if "%KV%"=="" set KV=fp8
set SPEC=%3
if "%SPEC%"=="" set SPEC=dflash2
cd /d D:\projects\qwen3.8_fast\build\b1\apps
if /i "%SPEC%"=="dflash2" (
  ninfer-serve.exe "%ART%" --host 127.0.0.1 --port 8099 --model-id qwen3.8-27b ^
    --max-context %CTX% --kv-capacity %CTX% --kv-dtype %KV% ^
    --max-concurrency 1 --greedy --no-thinking ^
    --spec dflash2 --lm-head-draft --draft-tokens 4 ^
    --request-log-jsonl D:\projects\qwen3.8_fast\models\cc_requests.jsonl ^
    --log-level info
) else (
  ninfer-serve.exe "%ART%" --host 127.0.0.1 --port 8099 --model-id qwen3.8-27b ^
    --max-context %CTX% --kv-capacity %CTX% --kv-dtype %KV% ^
    --max-concurrency 1 --greedy --no-thinking ^
    --spec mtp --draft-tokens 3 ^
    --request-log-jsonl D:\projects\qwen3.8_fast\models\cc_requests.jsonl ^
    --log-level info
)
