@echo off
setlocal
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
set ART=D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer
cd /d D:\projects\qwen3.8_fast\build\b1\apps
ninfer-serve.exe "%ART%" --host 127.0.0.1 --port 8099 --model-id gpt-4o ^
  --max-context 8192 --kv-capacity 8192 --max-concurrency 1 --greedy --no-thinking ^
  --spec dflash2 --lm-head-draft --draft-tokens 4 --log-level warning
