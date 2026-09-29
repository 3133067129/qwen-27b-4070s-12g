@echo off
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
set ART=D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer
cd /d D:\projects\qwen3.8_fast\build\b1\apps
echo ==== DFlash2 lm-head-draft K=2 ====
ninfer.exe "%ART%" --prompt "Explain in two sentences why 1.58-bit ternary weights save memory." --no-thinking --spec dflash2 --lm-head-draft --draft-tokens 2 --max-new 200 > D:\projects\qwen3.8_fast\models\d2_2.out 2> D:\projects\qwen3.8_fast\models\d2_2.err
echo D2_K2_EXIT=%errorlevel%
echo ==== DFlash2 lm-head-draft K=4 ====
ninfer.exe "%ART%" --prompt "Explain in two sentences why 1.58-bit ternary weights save memory." --no-thinking --spec dflash2 --lm-head-draft --draft-tokens 4 --max-new 200 > D:\projects\qwen3.8_fast\models\d2_4.out 2> D:\projects\qwen3.8_fast\models\d2_4.err
echo D2_K4_EXIT=%errorlevel%
echo ALLDONE
