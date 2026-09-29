@echo off
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
cd /d D:\projects\qwen3.8_fast\build\b1\apps
ninfer.exe D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer --prompt "The capital of France is" --max-new 24 > D:\projects\qwen3.8_fast\models\ternary.out 2> D:\projects\qwen3.8_fast\models\ternary.err
echo RUN_EXIT=%errorlevel%
