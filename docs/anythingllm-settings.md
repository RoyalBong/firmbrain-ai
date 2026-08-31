# AnythingLLM Desktop settings (Phase 1)

AnythingLLM’s UI labels move between versions. Use this as a checklist, not a pixel-perfect screenshot. If a label differs, match **intent**: local Ollama only, small models, low RAM.

**Do not** set LLM or embedding providers to OpenAI, Anthropic, Gemini, or any hosted API. That would send prompts or document text off the LAN.

## 1. LLM (chat)

1. Open AnythingLLM Desktop.
2. Open **Settings** (or first-run onboarding).
3. **LLM provider** → **Ollama**.
4. Base URL: `http://127.0.0.1:11434`  
   (On this machine Ollama is native, not in Docker, so `host.docker.internal` is wrong.)
5. Model: `qwen2.5:1.5b`.
6. Do **not** select AnythingLLM’s **built-in / native** LLM as the workspace chat model. One local engine is enough for 8 GB RAM.

If the model list is empty, run `.\scripts\setup.ps1` and confirm `.\scripts\health-check.ps1` passes, then refresh the provider list.

## 2. Embeddings

1. **Embedding provider** → **Ollama**.
2. Model: `nomic-embed-text`.
3. Prefer Ollama embeddings over a second built-in embedder so you only load one embedding stack.

Vector DB: leave the **default bundled** database (LanceDB or whatever Desktop ships). Do not point at a cloud vector store.

## 3. Workspace: `GST Reference`

Create **one** workspace named exactly `GST Reference`.

**Workspace description / system prompt** (paste):

```
You are a drafting and reference aid for a Chartered Accountancy firm.
Answer only from the documents provided in this workspace when they are relevant.
Always show or rely on retrieved sources. If the documents do not contain the answer, say you do not know.
Do not invent GST rates, due dates, ITC eligibility, or blocked-credit (Block ITR) conclusions.
Staff must verify every citation against the source PDF before advising a client or filing.
```

## 4. RAG / chunking (keep RAM low)

Exact field names vary. Prefer the **low** end of each slider:

| Setting (typical name) | Phase 1 target | Why |
|---|---|---|
| Text splitter / chunk size | ~256–400 characters (or the lowest preset above ~200) | Smaller chunks, less RAM per query |
| Chunk overlap | Low (e.g. 0–50) | Less duplication |
| Max context / documents per query | 2–4 snippets | Retrieval is cheaper than a long context window |
| Context window / max tokens | Prefer 2048 if offered | KV cache grows with context |

If the UI only offers “default / performance / quality” presets, pick **performance** or **low resource**.

Upload the bundled files `data/gst-reference/GST-SAMPLE-*.md` first (eight notes). Wait until embedding finishes before chatting. Do not load Audit, ROC, ITR, or client workspaces on this PC.

## 5. What not to enable in Phase 1

- **Multi-user mode** — Docker only; not available on Desktop.
- **Enable network discovery** — exposes an unauthenticated API on the LAN; it does **not** give colleagues the chat UI. Leave off.
- Agents, web scraping, and third-party data connectors that call the internet.
- Anything that requires an API key for a cloud model.

## 6. After a rebuild

If you reinstall Desktop, walk this file again. Chat history and vectors live in the Desktop app’s local storage, not in this git repo. Treat Phase 1 as a pipeline proof; production data will live on the firm host in Phase 2.
