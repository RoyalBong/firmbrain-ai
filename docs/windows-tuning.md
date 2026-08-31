# Windows tuning (8 GB RAM, HDD, CPU-only)

This machine is below the firm’s production spec. These steps reduce freezes and make slow behaviour easier to interpret.

## Memory

- Close Outlook, Teams, extra browser tabs, and other heavy apps before pulling models or chatting.
- Increase the Windows **pagefile** (virtual memory) so Windows can swap instead of hard-locking:
  1. Settings → System → About → Advanced system settings → Performance → Settings → Advanced → Virtual memory → Change.
  2. Uncheck “Automatically manage”.
  3. Set a custom size. A reasonable starting point on 8 GB RAM is **initial 8192 MB, maximum 16384 MB** (8–16 GB). You need free disk space equal to the maximum.
  4. Restart if Windows asks.

A large pagefile does not make inference fast; it only reduces the chance of an OS freeze when Ollama + AnythingLLM + Chrome compete for RAM.

## Disk

- This PC uses a **5400 rpm HDD**. The first question after starting Ollama (cold start) can take several minutes while `qwen2.5:1.5b` loads. That is expected, not a hung app.
- If a **secondary SSD/NVMe** exists, set the user environment variable `OLLAMA_MODELS` to a folder on that drive, then restart Ollama. See `.env.example`.
- Do not store client PDFs on cloud-synced folders (OneDrive/Google Drive) that might upload them off the LAN.

## CPU / GPU

- There is **no CUDA GPU**. Do not install NVIDIA CUDA toolkits or configure GPU passthrough for this phase.
- Do not set `OLLAMA_HOST=0.0.0.0` (LAN bind). Keep `127.0.0.1`.

## Docker

- Do **not** install Docker Desktop on this machine for FirmBrain. See `deploy/production/README.md`.

## Sanity check before a test session

```powershell
.\scripts\health-check.ps1
```

If the health check fails, start Ollama from the Start menu and wait; HDD + antivirus can delay the API by a minute.
