# FirmBrain.AI
### Project Spec: Offline, LAN-Based AI Assistant for CA Firm

## 0. Context for the AI Coding Assistant (Cursor)

You are helping build **FirmBrain.AI** — a **private, offline AI assistant** for a Chartered Accountancy (CA) firm. This is a dual-purpose project:

1. **Production use**: The system will be deployed on a real office LAN and used daily by CA firm staff to query GST rules, audit checklists, and client documents.
2. **Personal tech project**: The builder holds a tech degree and wants this repo to demonstrate solid engineering practices (clean scripts, documentation, version control, testing) — treat this as a portfolio-worthy project, not just a quick hack.

Your job across this project: help write, debug, and refine Docker configs, shell/PowerShell scripts, and documentation described below. Ask clarifying questions if a step is ambiguous. Prioritize scripts that are idempotent (safe to re-run), well-commented, and cross-checked against official docs for Ollama and AnythingLLM (flag anything you're not fully certain about rather than guessing).

**Non-negotiable constraint**: No client data may ever leave the local network. Every design decision should be checked against this constraint.

---

## 1. Goal

Build a self-hosted, browser-accessible AI assistant that:
- Runs entirely on one machine inside the firm's office.
- Lets staff on the office LAN ask questions and get answers grounded in the firm's own documents (GST rules, audit checklists, client files).
- Has zero internet dependency after initial setup.
- Supports role-based access so staff only see the workspaces relevant to them.
- Is easy enough for a non-technical office admin to operate day-to-day once built.

---

## 2. Architecture Overview

Three components, all running on one host machine:

| Component | Role | Tool |
|---|---|---|
| LLM ("the Brain") | Understands questions, generates answers | Ollama (serves models locally on port 11434) |
| RAG + Vector DB ("the Filing Clerk") | Ingests documents, chunks/embeds them, retrieves relevant context | AnythingLLM (bundled vector DB) |
| Server + Network ("the Reception Desk") | Exposes a web UI to every device on the LAN | AnythingLLM's built-in server (port 3001) + office router |

Staff never install anything locally — they open a browser and go to an internal address (e.g., `http://192.168.1.50:3001` or a friendlier LAN alias like `http://ca-ai.local`).

---

## 3. Hardware Requirements

**Production/firm host machine (stays on; others connect to it):**
- Minimum: 16 GB RAM, 6-core CPU, 500 GB SSD
- Recommended: 32 GB RAM, RTX 3060 (12GB) or better GPU, 1 TB SSD
- No GPU is fine for RAG/search; only generation speed is affected.
- UPS/backup power strongly recommended (machine must stay up during business hours).

**Network:** Existing office router/switch is sufficient. No special hardware needed.

**Model sizing note for production (once real hardware is procured):**
- Lightweight/faster default: `qwen3:8b` or `llama3.2:3b`
- Heavier/higher-quality option (optional, run alongside): `qwen3:14b` or `llama3.3`
- Embedding model (always lightweight): `nomic-embed-text`

### 3a. Current Dev/Test Machine — Low-Spec Profile (IMPORTANT)

The builder is currently testing on a personal machine with **significantly below-recommended specs**. Cursor must optimize all scripts/configs for this profile first; production-grade settings above are for later, once better hardware is procured.

**Actual test machine specs:**
- OS: Windows 11
- CPU: Intel Core i3-1005G1 @ 1.2GHz (2 cores / 4 threads) — no dedicated GPU
- GPU: Intel UHD Graphics (integrated, not CUDA-capable — CPU inference only)
- RAM: 8 GB DDR4
- Disk: WDC WD10SPZX (5400rpm spinning HDD, **not** an SSD) — model load times will be slow regardless of model size

**Implications for the build:**
- **No GPU acceleration is possible.** All inference runs on CPU. Do not configure or reference GPU passthrough/CUDA anywhere in scripts for this phase.
- **RAM is the binding constraint.** With 8GB total (shared with Windows OS + AnythingLLM + Ollama + browser), only small models are viable. Large models (7B+) risk OS-level swapping/freezing, not just slowness.
- **Disk is slow (HDD, not SSD).** Model *load* time (cold start) will be noticeably slow even for small models; this is a one-time-per-session cost, not per-query, but should be expected and documented so it isn't mistaken for a bug.
- **Prefer AnythingLLM Desktop app over Docker for this phase.** Docker Desktop's background VM/daemon overhead is not affordable on 8GB RAM. Use Docker only later, when moving to proper production hardware with more headroom.

**Model choices for this phase (CPU-only, 8GB RAM):**

| Model | Approx. size | Purpose |
|---|---|---|
| `qwen2.5:1.5b` | ~1 GB | Default/fastest — start here. **Confirmed unreliable on nuanced terminology (ITR/ITC confusion) during Block ITR testing — see test-checklist.md.** |
| `gemma2:2b` | ~1.6 GB | Alternative if 1.5b quality is insufficient |
| `phi3:mini` (3.8B) | ~2.3 GB | Fallback if better reasoning is needed for complex queries; expect noticeably slower responses |
| Avoid 7B and above | — | High risk of unacceptable slowness or memory pressure on this hardware |

Embedding model stays `nomic-embed-text` regardless of phase — it's lightweight and not the bottleneck.

**Additional Windows-specific tuning for this machine:**
- Increase the Windows pagefile/virtual memory size to give extra buffer beyond the 8GB physical RAM.
- If any secondary SSD/NVMe storage is available on this machine, point Ollama's model storage directory (`OLLAMA_MODELS` env var) to it instead of the HDD.
- Close other memory-heavy applications (browser tabs, Outlook/Teams, etc.) during testing.
- In AnythingLLM settings, keep chunk size and per-query retrieved-chunk count on the lower end to reduce RAM pressure during retrieval.
- Test with **one workspace and a small document set first** (e.g., just GST Reference with a handful of files) before loading all domains — validate the pipeline works end-to-end before scaling document volume.

This low-spec profile is temporary for local development/testing only. Once validated, the same AnythingLLM workspace structure and document set can be migrated to proper firm hardware (Section 3) with larger models swapped in.

---

## 4. Software Components to Install

1. **Ollama** — free, open-source local model runner
2. **A chat model** — e.g., `qwen3:8b` (default/fast) and optionally `qwen3:14b` (for complex queries)
3. **nomic-embed-text** — embedding model for document search
4. **AnythingLLM (Docker deployment)** — workspace, document ingestion, and multi-user layer
5. **Docker + Docker Compose** — required to run AnythingLLM in multi-user server mode

Total software licensing cost: ₹0 (all open-source). Only hardware and setup time are costs.

---

## 5. Step-by-Step Build Plan

### Step 1 — Prepare the host machine
- Install a fresh OS: Windows 11 Pro or Ubuntu Linux (Linux preferred for server stability).
- Assign a fixed static local IP (e.g., `192.168.1.50`) via router DHCP reservation settings.
- Keep internet access enabled *only* during setup (Steps 1–6); it will be disabled in Step 9.

### Step 2 — Install Docker
- Install Docker Engine + Docker Compose (Linux) or Docker Desktop (Windows).
- Verify with `docker --version` and `docker compose version`.

### Step 3 — Write `docker-compose.yml`
Create a Compose file that runs two services:
- `ollama` — exposes port 11434, persists models to a named volume
- `anythingllm` — exposes port 3001, persists workspace/vector data to a named volume, depends on `ollama`, connects to it via the Docker network (use `host.docker.internal` or the service name `ollama` as the hostname depending on OS/network mode)

Requirements for this file:
- Both services must restart automatically (`restart: unless-stopped`).
- Use named volumes, not bind mounts, for model and app data (unless the builder wants documents easily browsable from the host — decide and document the choice).
- Include comments explaining each block (this is also a learning/portfolio artifact).

### Step 4 — Write a model-pull setup script (`setup.sh` / `setup.ps1`)
This script should:
- Wait for the Ollama container to be healthy before proceeding.
- Pull the chat model(s): `qwen3:8b` (and optionally `qwen3:14b`).
- Pull the embedding model: `nomic-embed-text`.
- Print the host's LAN IP and the URL staff should use.
- Be safe to re-run (skip re-pulling models already present).

### Step 5 — Configure AnythingLLM
- On first load (`http://<host-ip>:3001`), set:
  - LLM Provider → Ollama → point to the chat model
  - Embedding Provider → Ollama → `nomic-embed-text`
- Enable **Multi-User Mode** in settings.
- Document these settings in a config reference file so they survive a rebuild.

### Step 6 — Create Workspaces and load documents

**Target domains for this firm's use case:**
- GST (general reference + Input Tax Credit rules, including **Block ITR**/blocked credit scenarios)
- Audit Procedures & Checklists
- ROC (Registrar of Companies) compliance
- ITR (Income Tax Return) filing rules and procedures
- Case studies (firm's own worked examples/precedents)
- Client Files (per-client documents — access-restricted)

**Recommended workspace structure:**
- `GST Reference` — GST law, circulars, ITC/Block ITR rules
- `Audit Procedures & Checklists`
- `ROC Compliance`
- `ITR Filing Reference`
- `Case Studies & Precedents`
- `Client Files – Confidential` (access-restricted; consider one sub-workspace per major client if document volume is large)

**Rollout order (important for the low-spec dev machine — see Section 3a):**
Do not load all domains at once during initial testing. Start with a single workspace (e.g., `GST Reference`) and a small number of documents (5–10 files) to validate the full pipeline — upload → chunk/embed → query → citation — before expanding to the remaining domains. Expand workspace-by-workspace once each is confirmed working and response times are acceptable on the test machine.

- Upload PDFs/Word/Excel files relevant to each workspace.
- Document a naming convention and folder structure for source documents outside the app too (for backup/versioning purposes).

### Step 7 — Set up roles and accounts
- Roles to configure:
  - **Admin** (builder / IT person) — full control
  - **Manager** — can create workspaces, manage documents
  - **Default/staff user** — can chat only within permitted workspaces
- Map actual staff members to roles and workspace permissions; keep this mapping in a simple access-control doc (also useful for future compliance audits).

### Step 8 — Make it reachable over LAN
- Confirm the host's static IP.
- Optional: set up an internal DNS/hosts alias (e.g., `ca-ai.local`) so staff don't need to remember an IP.
- Test access from at least one other LAN device before continuing.

### Step 9 — Lock down internet access (true offline operation)
- Once models are downloaded and the system tested:
  - Block outbound WAN traffic for this machine at the router/firewall level (allow LAN traffic only).
  - Implement this via router firewall rules and/or OS-level firewall (Windows Defender Firewall / `ufw` on Linux).
- Write a small script or documented procedure for **temporarily re-enabling internet** (for controlled updates), then re-locking it down afterward. This should require a deliberate action, not be always-on.

### Step 10 — Testing
- Test with real staff questions: GST due dates, audit checklist steps, sample client queries.
- Verify AnythingLLM shows correct source citations for answers.
- Have 2–3 staff members test independently from their own desks before firm-wide rollout.
- Write a short test checklist/log documenting what was tested and results (useful both for QA and as project documentation).

### Step 11 — Ongoing data governance
- Assign a Data Custodian (builder or designated staff) responsible for uploads, access, and backups.
- Set up a backup script/cron job that copies the host's data volume to an external drive or local NAS (not cloud).
- Maintain an access log/register of who has access to which workspace.

---

## 6. Deliverables for This Repo

Cursor should help produce the following files:

```
firmbrain-ai/
├── docker-compose.yml
├── setup.sh              # Linux/macOS model-pull + health-check script
├── setup.ps1             # Windows equivalent
├── lockdown.sh           # Firewall lockdown script (Linux)
├── lockdown.ps1          # Firewall lockdown script (Windows)
├── backup.sh             # Backup script for data volumes
├── models.txt            # List of models to pull, with size/purpose notes
├── access-control.md     # Staff-to-role-to-workspace mapping (template)
├── test-checklist.md     # QA test log template
├── .env.example          # Environment variables template (ports, IPs, etc.)
└── README.md             # Full setup + operations guide, written for a non-technical office admin to follow
```

---

## 7. Stretch Goals (for the personal-project angle)

These aren't required for firm deployment but would strengthen this as a tech-degree portfolio project:

- **Model router**: a lightweight script/middleware that routes simple queries to the fast small model and complex/ambiguous queries to the larger model automatically.
- **Health-check/monitoring script**: periodic check that Ollama and AnythingLLM containers are up, with an alert (e.g., local log entry or email if reconnected briefly) if down.
- **Automated backup + restore test**: script that verifies backups are actually restorable, not just created.
- **Write-up**: a short technical report (architecture diagram, design decisions, tradeoffs like model size vs. speed, security model) — useful both as internal documentation and as a portfolio piece.

---

## 8. Compliance Note (non-technical, but important context)

This setup keeps all data on-premises with no external API calls once locked down, addressing the core data-residency requirement for client information. However, specific compliance obligations (retention periods, audit trail requirements, breach notification) should be reviewed by the firm's compliance/legal advisor against the final implementation — some details (e.g., log retention duration) may carry legal weight beyond the technical build. This is a reminder to loop in that review; it is not something to solve in code alone.

### 8a. Accuracy Note for Financial/Tax Domains (ROC, ITR, GST, Block ITR)

Because this assistant will answer questions on compliance-sensitive topics (ROC filings, ITR procedures, GST including Block ITR/blocked credit rules), keep in mind:
- Smaller models (see Section 3a) are more likely to produce plausible-sounding but incorrect answers on nuanced, multi-step tax/compliance logic than a qualified professional would.
- The RAG pipeline (AnythingLLM) grounds answers in the firm's uploaded documents and shows citations — this materially reduces (but does not eliminate) the risk of fabricated answers, since the model is retrieving from real source material rather than only using its general training knowledge.
- Treat this tool as a **drafting/reference aid for staff**, not a final authority — outputs on filing deadlines, ITC eligibility, or ROC obligations should be verified against the source document/citation shown, especially before anything is communicated to a client or filed.
- Consider adding a standing disclaimer in the AnythingLLM workspace description or system prompt reminding staff to verify citations before relying on an answer.

---

## 9. Open Questions to Resolve Before/During Build

Cursor: flag these back to the builder if not yet decided —
1. Windows or Linux host OS?
2. Exact staff list and role assignments for Step 7?
3. Preferred LAN alias name (e.g., `ca-ai.local`) vs. plain static IP?
4. Backup destination: external drive or local NAS? What retention period?
5. Which chat model(s) to run by default given the actual host hardware once finalized?
