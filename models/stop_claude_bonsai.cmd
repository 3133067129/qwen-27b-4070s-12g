@echo off
rem Stop the local engine and release its ~7-9 GiB of VRAM.
taskkill /f /im ninfer-serve.exe >nul 2>&1
if errorlevel 1 (echo engine was not running) else (echo engine stopped)
