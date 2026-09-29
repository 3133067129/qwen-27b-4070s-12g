@echo off
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
cd /d D:\projects\qwen3.8_fast\build\b1\apps
echo ==== RUN A: direct answer, no thinking ====
ninfer.exe D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer --prompt "Write one sentence explaining what a ternary weight is." --no-thinking --max-new 120 > D:\projects\qwen3.8_fast\models\tA.out 2> D:\projects\qwen3.8_fast\models\tA.err
echo RUN_A_EXIT=%errorlevel%
echo ==== RUN B: MTP speculative, K=2 ====
ninfer.exe D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer --prompt "Explain in two sentences why 1.58-bit ternary weights save memory." --no-thinking --spec mtp --draft-tokens 2 --max-new 200 > D:\projects\qwen3.8_fast\models\tB.out 2> D:\projects\qwen3.8_fast\models\tB.err
echo RUN_B_EXIT=%errorlevel%
