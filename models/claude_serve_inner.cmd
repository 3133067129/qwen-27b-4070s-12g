@echo off
rem Engine for Claude Code.
rem  Long-context profile: rk4v4-e8 KV (compact sm_89 lattice KV, ~18 KiB/token)
rem  + explicit kv-capacity give this 12 GB card a 131072-token window. MTP3 is
rem  required - DFlash2's draft state caps the pool at ~40k on this card. No
rem  --kv-capacity auto: auto reserves an extra 1 GiB headroom that shrinks the
rem  pool. No --wddm-evictable-budget: that flag requires a GPU that does NOT drive
rem  a display, and this card drives one. IMPORTANT: the engine needs the VRAM free -
rem  Ollama must not have a big model loaded (see litellm-multimodel-proxy note).
setlocal
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;%PATH%"
set ART=D:\projects\qwen3.8_fast\models\bonsai2_27b_ternary.ninfer
cd /d D:\projects\qwen3.8_fast\build\b1\apps
ninfer-serve.exe "%ART%" --host 127.0.0.1 --port 8099 --model-id qwen3.8-27b ^
  --max-context 131072 --kv-capacity 131072 --kv-dtype rk4v4-e8 ^
  --max-concurrency 1 --greedy --no-thinking ^
  --spec mtp --draft-tokens 3 --lm-head-draft ^
  --request-log-jsonl D:\projects\qwen3.8_fast\models\cc_requests.jsonl ^
  --log-level info > D:\projects\qwen3.8_fast\models\claude_serve.log 2>&1
