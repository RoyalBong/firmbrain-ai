# Production deployment (Phase 2+) — not for this laptop

FirmBrain’s office deployment uses **Docker Compose**: Ollama + AnythingLLM on ports 11434 and 3001, named volumes, `restart: unless-stopped`, and multi-user mode.

That stack is **not** included as a runnable `docker-compose.yml` in Phase 1 on purpose.

## Why it is deferred

The current test machine is Windows 11 with **8 GB RAM**, a dual-core CPU, a spinning HDD, and no CUDA GPU. Docker Desktop’s VM would compete with native Ollama and AnythingLLM Desktop and is likely to freeze the OS.

Phase 1 therefore runs:

- Ollama **native** on `127.0.0.1:11434`
- AnythingLLM **Desktop** (single user, no staff browser UI)

## When to add Compose

Add `docker-compose.yml` in this directory when moving to firm hardware that meets the spec (16 GB RAM minimum; 32 GB + GPU recommended). Until then:

- Do not install Docker Desktop on the 8 GB test PC for this project.
- Do not expose Ollama on `0.0.0.0`.
- Do not enable AnythingLLM Desktop “network discovery” as a substitute for the staff UI (it exposes an unauthenticated API, not the chat interface).

Workspaces and documents created in Desktop can be recreated or migrated on the firm host; treat Phase 1 as a pipeline proof, not the production data store.
