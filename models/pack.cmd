@echo off
set PY=C:\Users\Administrator\AppData\Local\Programs\Python\Python311\python.exe
set PYTHONPATH=D:\projects\qwen3.8_fast\ninfer-4070s-12g
%PY% D:\projects\qwen3.8_fast\tools\pack.py %*
echo PACK_EXIT=%errorlevel%
