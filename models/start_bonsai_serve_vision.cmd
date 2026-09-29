@echo off
rem Vision + DFlash2 on a 12 GB card: KV is cut to 4096 because the Vision allocations,
rem the Q4 draft head and an 8192-token KV reservation together exceed the free VRAM
rem (measured: needs 1740134656 B of runtime, only 1537248256 B available at 8192).
setlocal
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
set ART=D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer
cd /d D:\projects\qwen3.8_fast\build\b1\apps
ninfer-serve.exe "%ART%" ^
  --host 127.0.0.1 --port 8099 ^
  --max-context 4096 --kv-capacity 4096 ^
  --max-concurrency 1 --greedy --no-thinking ^
  --vision ^
  --spec dflash2 --lm-head-draft --draft-tokens 4 ^
  --log-level warning
