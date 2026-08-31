#Requires -Version 5.1
<#
.SYNOPSIS
  Idempotent Phase 1 setup: wait for native Ollama, pull models from models.txt.

.DESCRIPTION
  Does not install Ollama or AnythingLLM. Install those first (see README.md).
  Safe to re-run: models already present are skipped.

  Phase 1 is CPU-only on 8 GB RAM. Do not pull 7B+ models on this machine.

.PARAMETER IncludeOptional
  Also pull models marked "optional" in models.txt (gemma2:2b, phi3:mini).

.PARAMETER OllamaUrl
  Ollama API base URL. Default localhost only.
#>
[CmdletBinding()]
param(
    [switch]$IncludeOptional,
    [string]$OllamaUrl = "http://127.0.0.1:11434",
    [int]$ReadyTimeoutSec = 120
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ModelsFile = Join-Path $RepoRoot "models.txt"

function Write-Info([string]$Message) { Write-Host $Message }
function Write-Warn([string]$Message) { Write-Host "WARNING: $Message" -ForegroundColor Yellow }
function Write-Fail([string]$Message) { Write-Host "ERROR: $Message" -ForegroundColor Red }

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Fail "ollama is not on PATH. Install Ollama for Windows from https://ollama.com/download then re-run this script."
    exit 1
}

if (-not (Test-Path $ModelsFile)) {
    Write-Fail "models.txt not found at $ModelsFile"
    exit 1
}

function Get-FirmBrainModels {
    param([string]$Path, [switch]$OptionalToo)
    $rows = @()
    Get-Content -LiteralPath $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $parts = $line -split "\s+", 3
        if ($parts.Count -lt 2) { return }
        $name = $parts[0]
        $tier = $parts[1].ToLowerInvariant()
        $purpose = if ($parts.Count -ge 3) { $parts[2] } else { "" }
        if ($tier -eq "required" -or ($OptionalToo -and $tier -eq "optional")) {
            $rows += [pscustomobject]@{ Name = $name; Tier = $tier; Purpose = $purpose }
        }
    }
    # Same empty-collection guard: an empty $rows would unroll to nothing
    # and leave $wanted = $null. Wrapping it preserves the array.
    return ,$rows
}

function Test-OllamaReady {
    param([string]$BaseUrl)
    try {
        $null = Invoke-RestMethod -Uri "$BaseUrl/api/tags" -Method Get -TimeoutSec 5
        return $true
    }
    catch {
        return $false
    }
}

function Get-InstalledModelNames {
    param([string]$BaseUrl)
    $names = New-Object System.Collections.Generic.HashSet[string]
    try {
        $payload = Invoke-RestMethod -Uri "$BaseUrl/api/tags" -Method Get -TimeoutSec 10
        foreach ($m in @($payload.models)) {
            if ($m.name) { [void]$names.Add([string]$m.name) }
        }
    }
    catch {
        Write-Warn "Could not list models via API; falling back to 'ollama list'."
        try {
            $list = & ollama list 2>&1 | Out-String
        }
        catch {
            # $ErrorActionPreference is "Stop" in this script, so a stderr
            # line from the native command can surface as an error record.
            # Treat any failure here as "no installed models".
            $list = ""
        }
        foreach ($line in ($list -split "`r?`n")) {
            if ($line -match "^(\S+)") {
                $n = $Matches[1]
                if ($n -ne "NAME") { [void]$names.Add($n) }
            }
        }
    }
    # IMPORTANT: PowerShell unrolls collections on the output pipeline, so
    # "return $names" with an EMPTY HashSet emits zero objects and the caller
    # would receive $null. The unary comma wraps it as a single object and
    # preserves the (possibly empty) set.
    return ,$names
}

function Test-ModelInstalled {
    param(
        [System.Collections.Generic.HashSet[string]]$Installed,
        [string]$Wanted
    )
    if ($Installed.Contains($Wanted)) { return $true }
    # Ollama may report "qwen2.5:1.5b" or "qwen2.5:1.5b-..." variants
    foreach ($have in $Installed) {
        if ($have -eq $Wanted -or $have.StartsWith("$Wanted-") -or $have.StartsWith("${Wanted}:")) {
            return $true
        }
    }
    return $false
}

Write-Info "FirmBrain.AI Phase 1 setup"
Write-Info "Repo: $RepoRoot"
Write-Info "Ollama: $OllamaUrl"
Write-Info ""

Write-Info "Waiting for Ollama to become ready (timeout ${ReadyTimeoutSec}s)..."
$deadline = (Get-Date).AddSeconds($ReadyTimeoutSec)
while (-not (Test-OllamaReady -BaseUrl $OllamaUrl)) {
    if ((Get-Date) -gt $deadline) {
        Write-Fail "Ollama did not respond at $OllamaUrl/api/tags. Start the Ollama app from the Start menu and retry."
        exit 1
    }
    Start-Sleep -Seconds 2
}
Write-Info "Ollama is ready."
Write-Info ""

$wanted = Get-FirmBrainModels -Path $ModelsFile -OptionalToo:$IncludeOptional
if ($wanted.Count -eq 0) {
    Write-Fail "No models selected from models.txt (required, or optional with -IncludeOptional)."
    exit 1
}

$installed = Get-InstalledModelNames -BaseUrl $OllamaUrl

foreach ($row in $wanted) {
    $name = $row.Name
    if (Test-ModelInstalled -Installed $installed -Wanted $name) {
        Write-Info "Skip (already present): $name"
        continue
    }
    Write-Info "Pulling $name  ($($row.Purpose))"
    Write-Warn "First pull needs internet. HDD cold start after pull can take several minutes — that is expected."
    & ollama pull $name
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "ollama pull failed for $name (exit $LASTEXITCODE)"
        exit $LASTEXITCODE
    }
    $installed = Get-InstalledModelNames -BaseUrl $OllamaUrl
}

Write-Info ""
Write-Info "----- Next steps -----"
Write-Info "Ollama API:              $OllamaUrl  (localhost only — do not set OLLAMA_HOST=0.0.0.0)"
Write-Info "AnythingLLM:            Desktop app (not http://localhost:3001 — that is Phase 2 Docker)"
Write-Info "Chat model:              qwen2.5:1.5b"
Write-Info "Embedding model:        nomic-embed-text"
Write-Info "Settings guide:         docs/anythingllm-settings.md"
Write-Info "Test checklist:          docs/test-checklist.md"
Write-Info ""
Write-Warn "On this HDD, the first query after a reboot is slow while the model loads from disk. That is not a bug."
Write-Warn "Close browsers/Teams/Outlook while testing. Do not enable Ollama on the LAN in Phase 1."
exit 0
