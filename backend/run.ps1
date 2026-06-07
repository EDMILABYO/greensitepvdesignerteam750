$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$pythonPath = Join-Path $scriptRoot "..\.venv\Scripts\python.exe"

if (-not (Test-Path $pythonPath)) {
    throw "Virtual environment not found at $pythonPath. Create it with: python -m venv .venv"
}

Set-Location $scriptRoot
& $pythonPath -m uvicorn app.main:app --reload