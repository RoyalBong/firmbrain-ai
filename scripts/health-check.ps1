#Requires -Version 5.1
<#
.SYNOPSIS
  Check that native Ollama is up and Phase 1 required models are installed.
#>
[CmdletBinding()]
param(
    [string]$OllamaUrl = "http://127.0.0.1:11434"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$ModelsFile = Join-Path $RepoRoot "models.txt"
$failed = $false

function Write-Fail([string]$Message) {
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Write-Ok([string]$Message) {
    Write-Host "OK:   $Message" -ForegroundColor Green
}

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Fail "ollama is not on PATH. Install from https://ollama.com/download"
    exit 1
}

try {
    $payload = Invoke-RestMethod -Uri "$OllamaUrl/api/tags" -Method Get -TimeoutSec 8
}
catch {
    Write-Fail "Ollama is not responding at $OllamaUrl/api/tags. Start the Ollama Windows app."
    exit 1
}

Write-Ok "Ollama API reachable at $OllamaUrl"

$installed = New-Object System.Collections.Generic.HashSet[string]
foreach ($m in @($payload.models)) {
    if ($m.name) {
        [void]$installed.Add([string]$m.name)
        Write-Host ("      model: {0}" -f $m.name)
    }
}

if ($installed.Count -eq 0) {
    Write-Host "      (no models installed yet — run scripts/setup.ps1)"
}

if (-not (Test-Path $ModelsFile)) {
    Write-Fail "models.txt missing at $ModelsFile"
    exit 1
}

Get-Content -LiteralPath $ModelsFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    $parts = $line -split "\s+", 3
    if ($parts.Count -lt 2) { return }
    $name = $parts[0]
    $tier = $parts[1].ToLowerInvariant()
    if ($tier -ne "required") { return }

    $found = $installed.Contains($name)
    if (-not $found) {
        foreach ($have in $installed) {
            if ($have -eq $name -or $have.StartsWith("$name")) { $found = $true; break }
        }
    }
    if ($found) {
        Write-Ok "required model present: $name"
    }
    else {
        Write-Fail "required model missing: $name  (run .\scripts\setup.ps1)"
        $failed = $true
    }
}

Write-Host ""
Write-Host "AnythingLLM is the Desktop app in Phase 1 (not port 3001)."
Write-Host "Do not bind Ollama to 0.0.0.0 on this machine."

if ($failed) { exit 1 }
exit 0
