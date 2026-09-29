@echo off
rem ===========================================================================
rem  Start the ternary Bonsai 2 27B engine for agent/OpenAI-compatible clients
rem  and WAIT until it is ready, so the client never hits the ~85 s cold load.
rem  Pair with models\.env (model id, base url, timeouts).
rem ===========================================================================
setlocal enabledelayedexpansion

rem Serve the model under this id. Change it to a name your tool hardcodes
rem (e.g. gpt-4o) and update OPENAI_MODEL/ANTHROPIC_MODEL in .env to match.
set MODEL_ID=qwen3.8-27b
set PORT=8099
set CTX=131072
rem KV storage: bf16 (default) | fp8 | int8 | k8v4 | rk4v4-e8.
rem rk4v4-e8 is the compact sm_89 lattice KV: ~18 KiB/token vs bf16's 192 KiB,
rem i.e. ~10x more window for free. This model is 16 attention + 48 GDN
rem (linear) layers, so only the 16 attention layers hold KV.
rem 131072 is the verified ceiling on this 12 GB card (MTP3 + rk4v4-e8);
rem DFlash2 caps at ~40k because its draft state eats fixed VRAM.
set KV=rk4v4-e8

set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
set ART=D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer
set APPS=D:\projects\qwen3.8_fast\build\b1\apps
set LOG=D:\projects\qwen3.8_fast\models\agents_serve.err

tasklist /fi "imagename eq ninfer-serve.exe" 2>nul | find /i "ninfer-serve.exe" >nul
if not errorlevel 1 (
  echo engine already running on port %PORT%
  exit /b 0
)

echo starting ternary Bonsai 2 27B (MTP3 K=3, 128k context, no thinking) on port %PORT% ...
start "ninfer-serve" /min "%~dp0serve_inner.cmd"

rem ping is used instead of "timeout /t" because timeout needs a console input handle
rem and fails instantly when the script runs without one (background/service context).
for /l %%i in (1,1,60) do (
  ping -n 6 127.0.0.1 >nul 2>&1
  curl.exe -s -f -o nul http://127.0.0.1:%PORT%/v1/models
  if not errorlevel 1 (
    echo engine ready: model id ^"%MODEL_ID%^"  base url http://127.0.0.1:%PORT%/v1
    exit /b 0
  )
)
echo FAILED to start - last log lines:
type "%LOG%" 2>nul | more +0
exit /b 1
