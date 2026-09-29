@echo off
rem Inner launcher: runs the engine with logging. Environment is inherited from
rem start_bonsai_agent.cmd (MODEL_ID / PORT / CTX / ART / APPS / LOG).
if "%MODEL_ID%"=="" set MODEL_ID=qwen3.8-27b
if "%PORT%"=="" set PORT=8099
if "%CTX%"=="" set CTX=131072
if "%KV%"=="" set KV=rk4v4-e8
if "%ART%"=="" set ART=D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer
if "%APPS%"=="" set APPS=D:\projects\qwen3.8_fast\build\b1\apps
if "%LOG%"=="" set LOG=D:\projects\qwen3.8_fast\models\agents_serve.err
"%APPS%\ninfer-serve.exe" "%ART%" ^
  --host 127.0.0.1 --port %PORT% --model-id %MODEL_ID% ^
  --max-context %CTX% --kv-capacity %CTX% --kv-dtype %KV% ^
  --max-concurrency 1 --greedy --no-thinking ^
  --spec mtp --lm-head-draft --draft-tokens 3 ^
  --log-level warning > "%LOG%" 2>&1
