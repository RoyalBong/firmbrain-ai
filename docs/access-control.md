# Access control -- staff, roles, workspaces

**Status:** template only. Phase 1 uses AnythingLLM Desktop (single user: the builder), so no real staff accounts exist yet. Fill this table in before Phase 2 (AnythingLLM as a multi-user server on the LAN) and keep it updated whenever someone joins, leaves, or changes workspace access. This file also serves as a record for compliance audits.

## Role reference

| Role | Typical capabilities |
|---|---|
| Admin | Builder / IT person -- full settings, users, workspaces |
| Manager | Can manage workspaces and documents; no LLM / embedder system settings |
| Staff | Chat only inside assigned workspaces |

## Workspaces (target domains from the project spec)

- `GST Reference`
- `Audit Procedures & Checklists`
- `ROC Compliance`
- `ITR Filing Reference`
- `Case Studies & Precedents`
- `Client Files - Confidential` (most restricted; consider one sub-workspace per major client)

## Staff-to-role-to-workspace mapping (fill in)

| Staff Name | Role (Admin/Manager/Staff) | Workspace Access |
|---|---|---|
| *(example: builder)* | Admin | All -- GST Reference, Audit Procedures & Checklists, ROC Compliance, ITR Filing Reference, Case Studies & Precedents, Client Files |
| *(fill in)* | | |
| | | |

Client Files should be the most restricted. Prefer one workspace (or sub-workspace) per major client when document volume grows.

## Data Custodian

| Field | Value |
|---|---|
| Name | |
| Responsible for | Uploads, access changes, local backups |
| Last review date | |

Do not store passwords here.