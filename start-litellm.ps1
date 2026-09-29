# start-litellm.ps1
# Starts the LiteLLM multi-model proxy on 127.0.0.1:8098 for this project.
#
# Exposes one Anthropic-compatible endpoint (/v1/messages) that fans out to:
#   - DeepSeek cloud   (needs DEEPSEEK_API_KEY)
#   - Ollama local     (http://127.0.0.1:11434)
#   - NInfer local     (http://127.0.0.1:8099, optional)
#
# Claude Code reads this address from its provider settings, so every
# conversation picks its model with /model.

$ErrorActionPreference = "Stop"

# --- Resolve DEEPSEEK_API_KEY ------------------------------------------------
# Tried in order:
#   1. $env:DEEPSEEK_API_KEY           - persistent user env var (the normal path)
#   2. HKCU\Environment\DEEPSEEK_API_KEY - the SAME variable, read from the registry
#   3. %USERPROFILE%\.deepseek-api-key  - opt-in key file, outside any repo
#   4. ~/.claude/settings.json          - last resort, see the warning below
#
# Why (2) exists: a launcher started by double-clicking a desktop shortcut
# inherits the environment block of the process that launched it. Explorer's
# block can predate a `setx`, so the variable is genuinely set yet invisible to
# the launcher. Reading the registry is deterministic and needs no key file.
#
# Why (4) is only a fallback: once Claude Code is pointed at this proxy,
# ANTHROPIC_AUTH_TOKEN in that file becomes the placeholder "sk-local", which is
# NOT a DeepSeek key. Forwarding it would 401 every cloud model while the port
# still binds and any readiness probe still passes - a silent failure. So a
# placeholder is rejected at every step rather than merely reported.
function Test-RealDeepSeekKey([string]$k) {
    if (-not $k) { return $false }
    $t = $k.Trim()
    return ($t.Length -gt 8 -and -not $t.StartsWith("sk-local"))
}

$key = $null
$keySource = $null

if (Test-RealDeepSeekKey $env:DEEPSEEK_API_KEY) {
    $key = $env:DEEPSEEK_API_KEY.Trim()
    $keySource = "environment variable"
} else {
    try {
        $reg = (Get-ItemProperty -Path 'HKCU:\Environment' -Name 'DEEPSEEK_API_KEY' -ErrorAction Stop).DEEPSEEK_API_KEY
        if (Test-RealDeepSeekKey $reg) {
            $key = $reg.Trim()
            $keySource = "registry HKCU\Environment (setx)"
        }
    } catch {
        # Not set in the registry - fall through.
    }
}

if (-not $key) {
    $keyFile = Join-Path $env:USERPROFILE ".deepseek-api-key"
    if (Test-Path $keyFile) {
        $fromFile = (Get-Content $keyFile -Raw).Trim()
        if (Test-RealDeepSeekKey $fromFile) {
            $key = $fromFile
            $keySource = $keyFile
        }
    }
}

if (-not $key) {
    $globalSettings = Join-Path $env:USERPROFILE ".claude\settings.json"
    if (Test-Path $globalSettings) {
        try {
            $token = (Get-Content $globalSettings -Raw -Encoding UTF8 | ConvertFrom-Json).env.ANTHROPIC_AUTH_TOKEN
            if (Test-RealDeepSeekKey $token) {
                $key = $token.Trim()
                $keySource = "$globalSettings (fallback)"
            }
        } catch {
            Write-Warning "Could not parse $globalSettings : $_"
        }
    }
}

if (-not $key) {
    Write-Host ""
    Write-Host "ERROR: no usable DEEPSEEK_API_KEY." -ForegroundColor Red
    Write-Host "  Refusing to start: the 3 deepseek-* models would 401 on every request" -ForegroundColor Red
    Write-Host "  while the port still binds and looks healthy." -ForegroundColor Red
    Write-Host ""
    Write-Host '  Fix:  setx DEEPSEEK_API_KEY "sk-..."' -ForegroundColor Red
    Write-Host "        then run this script again (no need to reopen the terminal)." -ForegroundColor Red
    exit 1
}

$env:DEEPSEEK_API_KEY = $key
Write-Host "DEEPSEEK_API_KEY resolved from $keySource" -ForegroundColor Green
if ($keySource -like "*fallback*") {
    Write-Host "  WARNING: this fallback disappears once Claude Code is pointed at this proxy." -ForegroundColor Yellow
    Write-Host '  Persist it with:  setx DEEPSEEK_API_KEY "<key>"' -ForegroundColor Yellow
}

Set-Location $PSScriptRoot
Write-Host "Starting LiteLLM on http://127.0.0.1:8098 ..." -ForegroundColor Cyan
Write-Host "Models are listed at http://127.0.0.1:8098/v1/models" -ForegroundColor DarkGray
litellm --config litellm.yaml --port 8098 --host 127.0.0.1
