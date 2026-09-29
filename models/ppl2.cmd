@echo off
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
cd /d D:\projects\qwen3.8_fast\build\b1\apps
ninfer-perplexity.exe D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer --text D:\projects\qwen3.8_fast\models\corpus_small.txt --context 256 --stride 128 > D:\projects\qwen3.8_fast\models\ppl2.out 2> D:\projects\qwen3.8_fast\models\ppl2.err
echo PPL_EXIT=%errorlevel%
