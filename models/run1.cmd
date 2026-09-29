@echo off
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
cd /d D:\projects\qwen3.8_fast\build\b1\apps
ninfer.exe D:\projects\qwen3.8_fast\models\qwen3_8_27b.ninfer --prompt "The capital of France is" --max-new 16 > D:\projects\qwen3.8_fast\models\run1.out 2> D:\projects\qwen3.8_fast\models\run1.err
echo RUN_EXIT=%errorlevel%
