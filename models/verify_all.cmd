@echo off
set PY=C:\Users\Administrator\AppData\Local\Programs\Python\Python311\python.exe
set PYTHONPATH=D:\projects\qwen3.8_fast\ninfer-4070s-12g
cd /d D:\projects\qwen3.8_fast\tools\verify
set ART=D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer
set GGUF=D:\projects\qwen3.8_fast\models\Ternary-Bonsai-2-27B\Ternary-Bonsai-2-27B-PQ2_0.gguf
echo ########## check_signs ##########
%PY% check_signs.py "%ART%" D:\projects\qwen3.8_fast\models\bonsai_hadamard_meta.json
echo SIGNS_EXIT=%errorlevel%
echo ########## check_payload_order ##########
%PY% check_payload_order.py "%ART%" text/layers/0/gdn/output
echo PAYLOAD_EXIT=%errorlevel%
echo ########## check_row_order ##########
%PY% check_row_order.py "%ART%" "%GGUF%"
echo ROWORDER_EXIT=%errorlevel%
echo ########## check_assembly ##########
%PY% check_assembly.py "%ART%" "%GGUF%"
echo ASSEMBLY_EXIT=%errorlevel%
