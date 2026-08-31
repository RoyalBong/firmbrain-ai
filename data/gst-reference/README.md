# GST Reference — local document drop folder (Phase 1)

This folder already contains **8 SAMPLE markdown notes** (`GST-SAMPLE-*.md`) so you can test upload → embed → cite without collecting PDFs. They are teaching summaries, **not** official CBIC text.

Put additional **5–10 non-client** files here if you want (public circulars, firm checklists without client names).

## What belongs here

- The bundled `GST-SAMPLE-*.md` files (upload these first)
- Public GST circulars, rate notes, or firm-internal **non-client** checklists
- Files you will upload into the AnythingLLM workspace named `GST Reference`

## What does not belong here

- Client working papers, invoices, PAN/Aadhaar scans, or any personally identifiable client data
- Those files stay out of git. This folder’s binaries are gitignored (`*.pdf`, Office files).

## Naming

Follow [docs/source-documents.md](../../docs/source-documents.md). Example:

```
GST-ITC-blocked-credit-overview.pdf
GST-return-due-dates-reference.pdf
```

After files are on disk, upload them in AnythingLLM Desktop (do not rely on this folder being auto-ingested).
