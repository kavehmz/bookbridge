# CLAUDE.md — Bilingual German Readers

## What this repo is

A small factory for turning **public-domain English books** into **bilingual
"Ilya-Frank-method" reading PDFs and EPUBs** that help me (the owner) learn
German fast. I'm working toward German citizenship and want lots of immersive
reading with built-in vocabulary help.

If you are reading this on a freshly cloned machine: the **books themselves are
not in the repo** (see `.gitignore`) — only the *procedure, scripts, and docs*
are. Your job, when I ask, is to take a new Gutenberg book and produce the same
high-quality bilingual reader you'll see described below. **`instruction.md` is
the detailed step-by-step playbook — read it.** This file is the orientation.

## Current direction (latest owner preference)

The original project format is English-first, but the owner's latest preferred
learning mode is **German-first / "Deutsch zuerst"**:

- German is the base reading text.
- English support goes into inline `[(...)]{.de}` spans only as help.
- For pronunciation, generate **two EPUB 3 Media Overlay variants from the same
  ElevenLabs cache**:
  - **Apple Books fixed-layout**: synchronized audio works in Apple Books, but
    pages behave like PDF pages and font controls are limited.
  - **BookFusion reflowable**: synchronized audio works in BookFusion, with
    normal EPUB font controls.
- Kindle/Paperwhite is still useful for ordinary reading, but it is not the
  target for custom synchronized audio.
- For ElevenLabs API generation, default to **`eleven_flash_v2_5`** unless the
  owner explicitly asks for higher quality. It sounded at least as clear to the
  owner and is cheaper than `eleven_multilingual_v2`.

This is not meant to be Dracula-only. The decisions are general for future
books. The current implementation, however, lives inside
`books/<Title> (Deutsch zuerst)/scripts/` and should be copied/promoted for the
next book until the tooling is moved to a shared repo-level scripts directory.

## The original English-first format (still supported)

The **Ilya-Frank reading method**: the English original flows normally, and after
each small chunk the German translation is inserted inline in parentheses, in a
warm brick-red italic, with short vocab/grammar side-notes. Example (the gold
standard — match it):

```
"You could not possibly have come at a better time [(„Sie hätten gar nicht zu einer besseren Zeit kommen können; could not possibly – unmöglich; wörtl.: hätten unmöglich kommen können)]{.de}, my dear Watson," he said cordially [(mein lieber Watson“, sagte er herzlich; cordially – herzlich)]{.de}.
```

`sample.png` is the visual reference for the look.

### Non-negotiable style rules for English-first editions
1. **English is the base text; German goes in the parentheses.** For the newer
   German-first edition, use `instruction.md` §14 and §16 instead.
2. **Chunks are small** (3–10 English words), phrase-level, NOT whole sentences.
3. **The side-notes are the whole point — keep them generous.** `English headword
   – German`, plus `der/die/das` for nouns and principal parts for irregular
   verbs. Never trim them as "redundant"; add more freely. (An external reviewer
   once told me to cut them; I overruled that. Keep them.)
4. **German must be idiomatic and natural, never word-for-word/wooden.**
5. **The bridge rule:** whenever the natural German diverges from the English
   (reordered, idiomatic, a compound), the note must show what maps to what — key
   word-mappings and/or a literal rendering marked `wörtl.: …`. I'm a beginner and
   must never lose track of which German is which English.
6. **Register:** correct du/Sie for who is speaking (family/friends = du;
   strangers/officials/period gentlemen = Sie). Keep it consistent.
7. **Outputs: both PDF and EPUB.**
8. **Markdown convention:** the German gloss is a pandoc span `[(...)]{.de}` with
   plain text inside (no `*`, `_`, backticks inside the span). Preserve the
   original English faithfully, including `_underscore emphasis_` outside spans.
   German speech uses „ "; English uses " ".

## The toolchain (everything runs in podman — nothing installed on the laptop)

The Mac is Apple Silicon (**arm64**); the official `pandoc/latex` image is
amd64-only, so we build our own small arm64 image **once**:

```sh
podman build -t bilingual-book:latest -f build/Containerfile build/
```

(`docker` is aliased to `podman`. The podman machine is already running.)

`/build/` holds the canonical, generic assets (copied into each book):
- `Containerfile` — Ubuntu + pandoc + minimal TeX Live + poppler-utils (arm64).
- `de-span.lua` — renders `[(...)]{.de}` as colored italic in the **PDF** (LaTeX).
- `pagebreak.lua` — each chapter starts on a new page (PDF).
- `header.tex` — Palatino (`mathpazo`), gloss color `\definecolor{germ}{HTML}{8A3B2A}`, spacing.
- `epub.css` — styles `span.de` for the **EPUB** (same look).
- `build-book.sh` / `build-epub.sh` — **generic**: derive the book dir from their
  own location and include every top-level `markdown/*.md` in sorted order, so
  files just need reading-order names (`00-howto.md`, `ch01.md`…/`story01.md`…).
- `metadata.yaml` — title/subtitle/author template (edit per book).

PDF engine is **pdflatex** (handles ä ö ü ß and dashes/quotes natively; avoids
fontspec/xelatex font hassle).

## Repo layout (git-ignored vs committed)

- **`texts/<Book>/pgNNNNN.txt`** — local cache of downloaded Gutenberg files
  (re-downloadable; **not committed**).
- **`books/<Book Title>/`** — the working directory (**not committed**):
  ```
  source/    chNN_raw.txt …            (English extracted from the cached .txt)
  markdown/  00-howto.md, chNN.md …    (bilingual; [(...)]{.de} spans, optional ::: grammar boxes)
  markdown/parts/                      (sub-agent segment outputs, before assembly)
  german-only/                         (clean German text for TTS/audio)
  audio-elevenlabs-timed/              (cached per-chapter MP3 + timing JSON)
  media-overlay-books/                 (fixed Apple Books + reflowable BookFusion read-aloud EPUBs)
  build/     (copy of /build, metadata.yaml edited)
  pdf/       (the generated .pdf and .epub)
  ```
- **Committed:** `/build` (canonical generic assets), `CLAUDE.md`,
  `instruction.md`, `README.md`, `docs/` (screenshots), `sample.png`, `prompt.md`,
  `.gitignore`. See `.gitignore` (allow-list: anything new at the root is ignored
  by default).

## The procedure (summary — full version in `instruction.md`)

1. **Get the text.** Use the cached `texts/<Book>/pgNNNNN.txt` if present, else
   download it there from gutenberg.org (public domain only). Strip the
   header/footer/license; find chapter or story boundaries.
2. **Split.** Extract each chapter/story; split into ~280-line **segments** at
   blank-line (paragraph) boundaries — never cut mid-paragraph.
   - ⚠️ The shell is **zsh** (1-indexed arrays). Run index-math loops under
     `bash -c '…'` or you get off-by-one bugs.
3. **Translate via a Workflow** — one sub-agent per segment, each reads its
   `source/…_raw.txt`, writes `markdown/parts/…md` (body only, NO heading),
   returns a small status. Use the brief in `instruction.md` (plain conversational
   German for dialogue-heavy books; extra-small chunks for ornate prose).
   - ⚠️ Workflow `args` did not reach the script once — **inline the work-list
     (the per-chapter segment-count spec) directly in the script**, don't pass via args.
4. **Validate** every part: file present and non-empty; `[(` count == `)]{.de}`
   count (balanced spans); no stray chapter/roman markers. **Re-translate any
   straggler** (missing status, truncated, or unbalanced) with a direct Agent call.
5. **Assemble** each chapter/story into `markdown/<name>.md` with a heading
   `# <English Title> · <Deutscher Titel>` (or `# Chapter N · Kapitel N`), then the
   segments concatenated. Add `markdown/00-howto.md`. ⚠️ Keep the words "Project
   Gutenberg" (and their header/footer) OUT of the output — it's a trademark that
   attaches their license. Use a neutral "public-domain text + AI/unofficial" credit.
6. **Build** PDF + EPUB via `build/build-book.sh` and `build/build-epub.sh`.
   - ⚠️ **Stray exotic Unicode breaks pdflatex** (EPUB is fine). Agents sometimes
     emit `・` (U+30FB) for `·`, or `ʼ` (U+02BC) for an apostrophe. Scan the
     assembled markdown and normalize before building (see `instruction.md` for
     the one-liner and the safe character set).
7. **Grammar interludes (OPTIONAL).** If the owner wants them, weave in short
   teal grammar boxes (`::: grammar … :::`) — one point per box, every ~3–7 pages,
   anchored to a sentence just read, following a curriculum for the chosen CEFR
   level (A1–A2 / A2–B1 / A1–B1). Set the pace from the page count; if the book is
   too short to cover the level, say so and cover what fits. Grammar is opt-in — if
   not wanted, the book is the plain bilingual format. Full spec: `instruction.md` §9.
   A second opt-in layer — **Wortbildung & Etymologie** (compound joints marked
   `Bahn·hof`, `(trennbar)` separable verbs, `Etym.:` word-stories for GERMAN words
   only, with the note language ramping English → bridged German → simple German
   across the book) — is specced in `instruction.md` §10.
8. **Spot-check** rendered pages (render a few to PNG with `pdftoppm` in the
   container, then view): title/TOC, a content page, a grammar box (if any).
9. **Report honestly** — it's machine translation of a whole book; offer quick
   per-chapter fixes + rebuild.
10. **For German-first audio editions**, see `instruction.md` §14 and §16:
    extract German-only text, generate cached ElevenLabs timestamped audio
    chapter by chapter, then build both fixed and reflowable EPUB 3 Media
    Overlay books from the cached chapters. Never regenerate a cached chapter
    unless the owner asks.

## To do a NEW book, just say something like:

> "New bilingual reader: <Title>, Gutenberg <URL>. Follow CLAUDE.md.
>  Grammar: none — or a level range like A1–A2."

Then: build the image if needed → make `books/<Title>/` → copy `/build` in, edit
`metadata.yaml` → extract+split → run the translation Workflow → validate →
assemble → (optional grammar pass) → build PDF+EPUB → spot-check → report. For
short-story collections, do one story per file, split each story into segments
(see `instruction.md`). If grammar isn't mentioned, ask once (level or none).

For the newer preferred mode, a fresh-session request may instead be:

> "New German-first read-aloud reader: <Title>, Gutenberg <URL>. Follow
> CLAUDE.md and instruction.md. German-first, EPUB3 media overlays for Apple
> Books fixed-layout and BookFusion reflowable, ElevenLabs Flash default. Reuse
> cached chapters; do not regenerate audio."

## Books already produced (for reference; not in the repo)

The Adventures of Sherlock Holmes + The Return of Sherlock Holmes (Doyle),
The Time Machine (Wells), Dracula (Stoker), Frankenstein (Shelley). Difficulty
ladder easiest → hardest: Time Machine → the Holmes collections → Dracula
(longest) → Frankenstein (ornate 1818 prose). *Oliver Twist* (Dickens) is the
obvious next big one if I ask.

## Boundaries
- Public-domain Gutenberg texts only; personal study use only; not for
  distribution. I delete generated books when done.
- Do not print or commit the ElevenLabs API key. The local `.elevenlabs.env`
  lives at repo root and is ignored by git.
- Only `/build`, `/docs`, and the docs (`CLAUDE.md`, `instruction.md`, `README.md`,
  `.gitignore`, `sample.png`, `prompt.md`) are committed. `texts/` and `books/`
  are local-only working data — never commit them.
