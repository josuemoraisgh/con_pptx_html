@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_web_pptx.ps1" %*
