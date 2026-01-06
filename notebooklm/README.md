# NotebookLM Capture (Version-Control Friendly)

NotebookLM notebooks (like `https://notebooklm.google.com/notebook/35d7301f-8fa7-4bd0-b7b8-e492060404de`) require an authenticated Google session and will redirect to Google login when accessed from automation.

This folder provides a **safe, credential-free** way to capture NotebookLM content into this repository:
- Store **copied notes / exported text** as Markdown
- Track **what was imported, when, and from where** (metadata + hashes)

## How to capture a NotebookLM notebook

1. Open the notebook in your browser (signed in).
2. Copy the relevant content (Notes / responses / source list) into a local file:
   - Preferred: `NOTES.md`
   - OK: `notes.txt`
3. Import it into the repo with the helper script:

```powershell
.\import-notebooklm-notes.ps1 `
  -NotebookUrl "https://notebooklm.google.com/notebook/35d7301f-8fa7-4bd0-b7b8-e492060404de" `
  -InputPath "C:\Path\To\NOTES.md"
```

## Output layout

Each NotebookLM notebook is stored under:

`notebooklm/notebooks/<notebookId>/`
- `NOTES.md` (canonical, human-edited copy)
- `raw/` (timestamped snapshots of imported files)
- `metadata.json` (import provenance + hashes)

## Why this is manual

- NotebookLM is behind Google authentication.
- This repository **must not** store Google cookies/tokens.
- Manual capture keeps the workflow secure and auditable.

