@echo off
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
set ART=D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer
cd /d D:\projects\qwen3.8_fast\build\b1\apps
echo ==== D: DFlash2 spec, K=2 ====
"%CD%\ninfer.exe" "%ART%" --prompt "Explain in two sentences why 1.58-bit ternary weights save memory." --no-thinking --spec dflash2 --draft-tokens 2 --max-new 200 > D:\projects\qwen3.8_fast\models\tD.out 2> D:\projects\qwen3.8_fast\models\tD.err
echo RUN_D_EXIT=%errorlevel%
echo ==== E: MTP K=3 ====
"%CD%\ninfer.exe" "%ART%" --prompt "Explain in two sentences why 1.58-bit ternary weights save memory." --no-thinking --spec mtp --draft-tokens 3 --max-new 200 > D:\projects\qwen3.8_fast\models\tE.out 2> D:\projects\qwen3.8_fast\models\tE.err
echo RUN_E_EXIT=%errorlevel%
cd /d D:\projects\qwen3.8_fast\ninfer-4070s-12g
echo ==== F: VISION ====
"D:\projects\qwen3.8_fast\build\b1\apps\ninfer.exe" "%ART%" --messages examples/cli/messages/image_chart.json --vision --no-thinking --max-new 120 > D:\projects\qwen3.8_fast\models\tF.out 2> D:\projects\qwen3.8_fast\models\tF.err
echo RUN_F_EXIT=%errorlevel%
