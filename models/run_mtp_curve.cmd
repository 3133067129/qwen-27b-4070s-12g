@echo off
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
set ART=D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer
set P=Explain in two sentences why 1.58-bit ternary weights save memory.
cd /d D:\projects\qwen3.8_fast\build\b1\apps
for %%K in (1 2 3 4) do (
  echo ==== MTP K=%%K ====
  ninfer.exe "%ART%" --prompt "%P%" --no-thinking --spec mtp --draft-tokens %%K --max-new 200 > D:\projects\qwen3.8_fast\models\k%%K.out 2> D:\projects\qwen3.8_fast\models\k%%K.err
  echo K%%K_EXIT=!errorlevel!
)
echo ALLDONE
