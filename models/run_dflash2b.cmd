@echo off
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
set ART=D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer
cd /d D:\projects\qwen3.8_fast\build\b1\apps
echo ==== DFlash2 K=6 ====
ninfer.exe "%ART%" --prompt "Explain in two sentences why 1.58-bit ternary weights save memory." --no-thinking --spec dflash2 --lm-head-draft --draft-tokens 6 --max-new 200 > D:\projects\qwen3.8_fast\models\d2_6.out 2> D:\projects\qwen3.8_fast\models\d2_6.err
echo D2_K6_EXIT=%errorlevel%
echo ==== DFlash2 K=8 ====
ninfer.exe "%ART%" --prompt "Explain in two sentences why 1.58-bit ternary weights save memory." --no-thinking --spec dflash2 --lm-head-draft --draft-tokens 8 --max-new 200 > D:\projects\qwen3.8_fast\models\d2_8.out 2> D:\projects\qwen3.8_fast\models\d2_8.err
echo D2_K8_EXIT=%errorlevel%
echo ALLDONE
