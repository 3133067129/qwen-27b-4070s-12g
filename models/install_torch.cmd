@echo off
set PY=C:\Users\Administrator\AppData\Local\Programs\Python\Python311\python.exe
echo === attempt 1: SJTU pytorch mirror ===
%PY% -m pip install --quiet --index-url https://mirror.sjtu.edu.cn/pytorch-wheels/cu130 --extra-index-url https://pypi.tuna.tsinghua.edu.cn/simple torch safetensors numpy
echo sjtu_exit=%errorlevel%
%PY% -c "import torch;print('torch',torch.__version__,torch.cuda.is_available())" 2>&1
if errorlevel 1 (
  echo === attempt 2: download.pytorch.org ===
  %PY% -m pip install --quiet --index-url https://download.pytorch.org/whl/cu130 torch
  %PY% -m pip install --quiet --index-url https://pypi.tuna.tsinghua.edu.cn/simple safetensors numpy
  %PY% -c "import torch;print('torch',torch.__version__,torch.cuda.is_available())" 2>&1
)
echo INSTALL_DONE
