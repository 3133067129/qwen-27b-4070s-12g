@echo off
set PY=C:\Users\Administrator\AppData\Local\Programs\Python\Python311\python.exe
cd /d D:\projects\qwen3.8_fast\ninfer-4070s-12g
%PY% -m tools.convert.qwen3_8_27b.convert --model D:\projects\qwen3.8_fast\models\Qwen3.8-27B --dflash2-model D:\projects\qwen3.8_fast\models\Qwen3.8-27B-DFlash2 --out D:\projects\qwen3.8_fast\models\qwen3_8_27b.ninfer --device cuda > D:\projects\qwen3.8_fast\models\convert.log 2>&1
echo CONVERT_EXIT=%errorlevel%
