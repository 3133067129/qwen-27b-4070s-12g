@echo off
rem Start the ternary Bonsai 2 27B engine with the fastest measured configuration.
rem   --no-thinking        : answer directly (6-7x fewer tokens, higher accuracy on the 20-task suite)
rem   --spec dflash2       : DFlash2 speculative decoding
rem   --lm-head-draft      : REQUIRED with a ternary artifact (the full ternary LM head has no
rem                          linear_topk profile, so the optimized Q4 draft head must be used)
rem   --draft-tokens 4      : measured sweet spot (K=2 66, K=4 82, K=6 82, K=8 49 tok/s)
rem   --greedy              : temperature 0, reproducible
setlocal
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
set ART=D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer
cd /d D:\projects\qwen3.8_fast\build\b1\apps
echo serving on http://127.0.0.1:8099  (model id: qwen3.8-27b)
ninfer-serve.exe "%ART%" ^
  --host 127.0.0.1 --port 8099 ^
  --max-context 8192 --kv-capacity 8192 ^
  --max-concurrency 1 --greedy --no-thinking ^
  --spec dflash2 --lm-head-draft --draft-tokens 4 ^
  --log-level warning
