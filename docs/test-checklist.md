# Test checklist -- FirmBrain.AI

Copy this file for each testing round and fill it in as you go. A passing answer must be correct **and** show a citation pointing to an uploaded source document -- small models can sound confident while being wrong, so "Answer Correct = Y" without "Citation Shown = Y" is NOT a pass (see project-context.md Section 8a).

**Hardware note (Phase 1):** the test machine is 8 GB RAM / CPU-only / HDD. The first answer after starting Ollama can take a few minutes while the model loads from disk. Time it, and do not mark that as a failure if the answer eventually arrives with a source.

## Environment

| Item | Value |
|---|---|
| Date | |
| Tester | |
| `.\scripts\health-check.ps1` | pass / fail |
| Chat model | `qwen2.5:1.5b` (or other) |
| Embedding model | `nomic-embed-text` |
| Workspaces tested | |
| Files uploaded (names) | |
| Heavy apps closed before test | yes / no |

## Pipeline checks (once per workspace)

| # | Check | Expected | Pass? | Notes |
|---|---|---|---|---|
| 1 | Ollama running; `http://127.0.0.1:11434/api/tags` returns a model list | JSON response | | |
| 2 | AnythingLLM LLM provider is Ollama (local), not a cloud API | Local only | | |
| 3 | Workspace exists (e.g. `GST Reference`) with a "verify citations" disclaimer | Prompt saved | | |
| 4 | Documents uploaded and finished embedding | No errors; docs listed | | |

## Domain query tests (Step 10)

Ask 3-5 real staff questions per domain. Fill the last two columns in for every row.

| Question Asked | Expected Source Doc | Answer Correct (Y/N) | Citation Shown (Y/N) | Notes |
|---|---|---|---|---|
| GST: e.g. "What is the GSTR-3B due date for July?" | `GST-SAMPLE-due-date-workflow.md` | | | |
| GST: e.g. "When is ITC blocked under section 17(5)?" | `GST-SAMPLE-blocked-credit-17-5.md` | | | |
| What is Block ITR? | `GST-SAMPLE-blocked-credit-17-5.md` | N | N | Doc explicitly defines "Block ITR" = blocked ITC; model confused ITR/ITC terminology, never cited source, said term wasn't defined despite it being spelled out. |
| What does blocked credit mean in the sample blocked credit overview? (doc's own test question) | `GST-SAMPLE-blocked-credit-17-5.md` | Partial | N | Core definition roughly correct but repeats ITR/ITC confusion; claims term isn't defined despite being handed the definition directly. Reproducible failure. |
| ROC: e.g. "When is Form AOC-4 due for the last financial year?" | `ROC Compliance` workspace doc | | | |
| ROC: e.g. "What is Form DIR-3 KYC used for?" | `ROC Compliance` workspace doc | | | |
| ITR: e.g. "Which ITR form applies to a salaried employee?" | `ITR Filing Reference` workspace doc | | | |
| ITR: e.g. "Due date of ITR-1 when no audit applies?" | `ITR Filing Reference` workspace doc | | | |
| Audit: e.g. "List the first five steps of the audit checklist." | `Audit Procedures & Checklists` workspace doc | | | |
| Audit: e.g. "What sample size does the checklist require for receivables?" | `Audit Procedures & Checklists` workspace doc | | | |
| (add more real staff questions...) | | | | |

## Sign-off

| Question | Answer |
|---|---|
| Pipeline validated (upload -> retrieve -> cite)? | yes / no |
| All four domains answered with citations? | yes / no |
| Ready for the next workspace on this PC? | yes / no |
| Ready for Docker / LAN (Phase 2)? | only on firm hardware, not this laptop |

Failures: record RAM usage (Task Manager), whether the disk light stayed on during the query (model load), and whether citations were missing (RAG misconfiguration, not just "model too small").