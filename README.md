<<<<<<< HEAD
# FirmBrain.AI

Private, offline AI assistant for a Chartered Accountancy firm. Staff will eventually open a browser on the office LAN and ask questions grounded in the firm’s own GST, audit, ROC, ITR, and (later) client documents. **No client data may leave the local network.**

This repository is also a portfolio-quality ops project: idempotent scripts, documented settings, and a clear split between the low-spec test machine and the future office host.

Product spec: [project-context.md](project-context.md).

---

## For office staff (plain-English guide)

**What it is.** FirmBrain.AI is a private "ask anything" helper for the firm. You type a question in plain English (e.g. "When is GSTR-3B due for July?") and it answers using our own GST, audit, ROC, and ITR reference documents — not the public internet. All data and documents stay inside the office network; nothing is sent online.

**How to start it (Phase 1).**
1. Make sure the Ollama and AnythingLLM apps are running on the AI machine (icons in the taskbar / system tray).
2. Open **AnythingLLM Desktop**.
3. Pick a workspace (e.g. `GST Reference`), then type your question in the chat box.

**How to ask good questions.** Use plain English, like you would ask a colleague. The best answers come from documents that have been uploaded (GST rules, audit checklists, and similar).

**IMPORTANT — always check the citation.** FirmBrain.AI shows the source document behind each answer. Because it is a reference aid, open that citation and verify before telling a client or filing anything. An answer with no citation is a guess, not a fact.

**If something breaks.** First, restart the AnythingLLM and Ollama apps. If that does not help, contact the Data Custodian (the IT person / builder): Name ______, Phone/email ______.

**Phase 2 note (future):** staff will open a browser on the office LAN at `http://HOST_IP:3001`; this same plain-English guide will still apply.

---

## For the technical builder

### Current phase: Phase 1 (this laptop)

**Goal:** prove the pipeline — upload → chunk/embed → query → citation — on the builder’s Windows 11 machine.

| Constraint | Implication |
|---|---|
| 8 GB RAM, dual-core CPU, HDD, no NVIDIA GPU | CPU inference only; small models only |
| Docker Desktop is too heavy here | **Do not install Docker for this phase** |
| AnythingLLM Desktop is single-user | Only you use the UI; staff LAN access is Phase 2 |

| Component | What to run |
|---|---|
| LLM | Native [Ollama](https://ollama.com/download) on `http://127.0.0.1:11434` |
| Chat model | `qwen2.5:1.5b` (~1 GB) |
| Embeddings | `nomic-embed-text` |
| RAG UI | [AnythingLLM Desktop](https://anythingllm.com/download) (not Docker, not port 3001) |

Do **not** pull 7B+ models on this PC. Optional heavier small models (`gemma2:2b`, `phi3:mini`) are listed in [models.txt](models.txt) but are not pulled by default.

## What you install by hand (once)

Scripts cannot silently install GUI apps.

1. Install **Ollama for Windows**: https://ollama.com/download  
   Confirm the Ollama icon is in the system tray and `ollama --version` works in PowerShell.
2. Install **AnythingLLM Desktop**: https://anythingllm.com/download  
   Do not use AnythingLLM’s built-in LLM as the primary provider (it would use RAM twice). Point it at Ollama — see [docs/anythingllm-settings.md](docs/anythingllm-settings.md).
3. Follow [docs/windows-tuning.md](docs/windows-tuning.md) (pagefile, close heavy apps).

## Setup (repeatable)

In PowerShell from the repo root (if scripts are blocked, run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` first):

```powershell
.\scripts\setup.ps1
```

If you later want the optional models:

```powershell
.\scripts\setup.ps1 -IncludeOptional
```

Linux (future firm host or WSL — still native Ollama, not Docker in Phase 1):

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

Then configure AnythingLLM using [docs/anythingllm-settings.md](docs/anythingllm-settings.md). Upload the bundled `GST-SAMPLE-*.md` files from [data/gst-reference](data/gst-reference) into a workspace named `GST Reference` (add real public PDFs later). Run [docs/test-checklist.md](docs/test-checklist.md).

Health check:

```powershell
.\scripts\health-check.ps1
```

First query after a reboot can take a long time: the HDD is loading the model into RAM. That is expected.

## Architecture (where this is going)

```
Staff browsers (Phase 2+)  -->  AnythingLLM :3001  -->  Ollama :11434
                                      |
                                      +--> vector index of firm documents
```

- **Brain:** Ollama (local models only; no OpenAI/cloud keys).
- **Filing clerk:** AnythingLLM RAG with citations.
- **Reception (Phase 2):** AnythingLLM Docker, multi-user roles, LAN only.

Phase 1 uses Desktop instead of Docker. Desktop has **no** staff web UI. Do not turn on Desktop “network discovery” as a way to share the app: that exposes an unauthenticated API, not the chat interface. See [deploy/production/README.md](deploy/production/README.md).

## Later phases (not this repo commit)

| Phase | Work |
|---|---|
| 2 | Docker Compose on firm hardware (16 GB+ RAM); larger models; port 3001 |
| 3 | Static LAN IP, optional `ca-ai.local`, WAN lockdown, local backups |
| 4 | Remaining workspaces, staff roles, 2–3 staff UAT |
| Stretch | Model router, monitoring, restore drill, architecture write-up |

Open decisions (fill when known): staff roster, LAN alias vs IP, backup disk vs NAS and retention, production default chat model.

## Accuracy and compliance

This tool is a **drafting and reference aid**. Small models can sound confident and still be wrong on GST, ITC / blocked credit, ROC, and ITR. Staff must check the **citation** in AnythingLLM before telling a client or filing anything.

Client files never go in git. Workspace “Client Files” is Phase 4 on the office host. A compliance/legal review of retention and audit logs is still required (see Section 8 of the spec); that is not solved by software alone.

## Repo map

| Path | Role |
|---|---|
| [models.txt](models.txt) | Models to pull; required vs optional |
| [scripts/setup.ps1](scripts/setup.ps1) | Wait for Ollama, pull missing models |
| [scripts/setup.sh](scripts/setup.sh) | Same for Linux |
| [scripts/health-check.ps1](scripts/health-check.ps1) | API + required models |
| [docs/](docs/) | Settings, Windows tuning, naming, access template, QA log |
| [data/gst-reference](data/gst-reference) | Drop folder for Phase 1 GST files (binaries gitignored) |
| [.env.example](.env.example) | Environment template (ports, models, host IP) |
| [docs/access-control.md](docs/access-control.md) | Staff-to-role-to-workspace mapping template |

## License cost

Ollama and AnythingLLM are open source. Software licensing for this stack is ₹0. Hardware and setup time are the costs.
=======
# firmbrain-ai
Offline, LAN-based AI assistant for a CA firm — RAG-powered document Q&amp;A over GST, ROC, ITR, and audit knowledge, running entirely on local hardware with zero cloud dependency.
>>>>>>> 5083a1ec944767d6e4ed5764fb4328fe2c6a91c0
