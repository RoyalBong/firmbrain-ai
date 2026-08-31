# Source documents — naming and folders

Keep a copy of source files **outside** AnythingLLM so backups and versioning are possible. AnythingLLM is not the system of record.

## Rules

- **Never** put client working papers, identity documents, or tax workings in git.
- Phase 1 only uses **GST Reference** and **non-client** material (public circulars, internal checklists without client names).
- Binaries (`*.pdf`, Office files) are gitignored. Only READMEs in `data/` are tracked.

## Folder layout (on disk)

```
data/
  gst-reference/          # Phase 1 — start here
  audit-procedures/       # Phase 4
  roc-compliance/         # Phase 4
  itr-filing/             # Phase 4
  case-studies/           # Phase 4 — anonymise before use
  client-files/           # Phase 4 — never git; keep on the office host only
```

Create later folders when you expand domains. Do not ingest all of them on the 8 GB test PC.

## File naming

Use:

```
DOMAIN-topic-short-title-YYYY-MM.pdf
```

Examples:

- `GST-ITC-blocked-credit-overview-2024.pdf`
- `GST-GSTR-due-dates-reference.pdf`
- `AUDIT-cash-vouching-checklist-v1.docx`

Avoid spaces where possible; use hyphens. Include a date or version so two circulars on the same topic do not collide.

## After upload

- Record in [test-checklist.md](test-checklist.md) which files were ingested.
- If a file is replaced, delete the old embedding in AnythingLLM (or re-upload per app UI) so answers do not mix two versions of the law.
