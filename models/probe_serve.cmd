@echo off
rem probe config: DFlash2 K=4, no thinking, fp8 KV, large context
setlocal
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
set ART=D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer
cd /d D:\projects\qwen3.8_fast\build\b1\apps
ninfer-serve.exe "%ART%" --host 127.0.0.1 --port 8099 --model-id qwen3.8-27b ^
  --max-context %1 --kv-capacity %1 --kv-dtype %2 ^
  --max-concurrency 1 --greedy --no-thinking ^
  --spec dflash2 --lm-head-draft --draft-tokens 4 ^
  --request-log-jsonl D:\projects\qwen3.8_fast\models\cc_requests.jsonl ^
  --log-level info
