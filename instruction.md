# Bilingual Reader — Build Instructions & Playbook

This file is a complete, reusable spec for turning a public-domain book into a
**sentence/phrase-by-phrase bilingual reader** for fast German learning. It
combines the original request (`prompt.md`) with everything refined in the first
builds. Hand this file to Claude and say, e.g.:

> "Do a bilingual reader for **[Book Title]** — Gutenberg `[URL]`. Follow `instruction.md`."

…and it should run end-to-end without re-asking the questions we already settled.

---

## 1. Goal & context (the "why")

- I (the user) am learning German fast, in the middle of getting German
  citizenship, and want as much reading immersion as possible.
- Format wanted: **Ilya-Frank method** — the original English text flows
  normally, and after each small chunk the German appears inline in parentheses,
  in a distinct colour/italic, **with short vocab/grammar side-notes**.
- The reference look is `sample.png` in the project root.
- **Usage is personal study only.** Source must be public-domain
  (https://www.gutenberg.org). No selling, publishing, or distribution. I delete
  the files when done. (State this in the book's front matter / README.)
- All tooling must run in **podman** (Mac is Apple Silicon / arm64; `docker` is
  aliased to `podman`). Do **not** install things on the laptop.

---

## 2. Decisions already locked (do NOT re-ask these)

1. **Direction, old/default bilingual format:** English is the base/flowing text;
   **German goes in parentheses** as the helper. (Matches `sample.png`.)
   **Latest owner preference for active learning is now German-first** — see
   §14 and §16. Do not assume English-first if the owner says "latest",
   "Deutsch zuerst", "audio", "Apple Books", or "read-aloud".
2. **Chunking:** phrase-level, *not* always full sentences — typically 3–10
   English words per chunk, so each English bit sits right next to its German.
3. **Side-notes are the main learning value — keep them generous.** The little
   `English headword – German` notes (and noun genders, irregular verb principal
   parts, idiom dictionary forms) are LOVED. Never trim them as "redundant"; only
   remove a note if it is factually wrong. Adding more is good.
4. **German must be idiomatic, not word-for-word.** Translate the *meaning* the
   way a native speaker says it. Wooden calques are the #1 thing to avoid.
5. **The bridge rule** (because I'm a beginner and can lose track of what maps to
   what when the German is idiomatic/reordered): whenever the natural German
   diverges from the English, the side-note must carry the bridge — either the
   key word-mappings (`very much so – und ob`) and/or a literal rendering marked
   `wörtl.: …`. Natural German in the main gloss, literal bridge in the note.
6. **Register:** use correct du/Sie — family/friends/children = du; strangers/
   formal = Sie. (An LLM grading "green is better" got this wrong once; trust the
   social context of the scene.)
7. **Outputs:** both **PDF** and **EPUB**.
8. **Process flow:** start with a **Chapter-1 proof** only if the format is new or
   I ask; otherwise, since the format is now established, go straight to the full
   book. Use **sub-agents, one per chapter** (a Workflow) to keep context small.
9. **Scale:** translate at the **best model tier** for German quality (the work is
   token-heavy but quality matters most). Don't downgrade silently. Exception:
   for ElevenLabs TTS, the owner tested Flash vs Multilingual v2 and preferred or
   could not distinguish Flash; use `eleven_flash_v2_5` by default for audio.

---

## 3. Output format spec (exact)

Each chapter is a Markdown file. The German gloss is a pandoc span with class
`de`:

```
English chunk here [(deutsche Übersetzung; optionale Notiz)]{.de} more English [(...)]{.de}.
```

Rules for the Markdown:
- First line of each chapter file: `# Chapter N · Kapitel N`
- Re-flow the hard-wrapped Gutenberg text: each blank-line-separated block → one
  Markdown paragraph. Keep dialogue/paragraph breaks.
- Put the gloss span **after** the English chunk but **before** the trailing
  comma/period when it reads naturally (see gold example below).
- Inside a `[(...)]{.de}` span: **plain text only** (parentheses fine). Do **not**
  put Markdown `*`, `**`, or backticks inside. (Underscore `_emphasis_` carried
  from the source is tolerated — it renders as emphasis; but prefer not to add
  new markup.)
- Preserve the English faithfully, including `_underscore emphasis_` from the
  source (outside the spans).
- German speech inside a gloss uses German quotes „ "; English text uses " ".
- Notes use an en-dash `–` between the English headword and the German; separate
  multiple notes with `;`. Give `der/die/das` for nouns and principal parts for
  irregular verbs (e.g. `to feel, felt, felt – fühlen`).

**Gold example** (the standard to match):
```
I had called upon my friend, Mr. Sherlock Holmes [(Ich hatte meinen Freund, Mr. Sherlock Holmes, besucht; to call upon sb – jdn. besuchen)]{.de}, one day in the autumn of last year [(eines Tages im Herbst des letzten Jahres; the autumn – der Herbst)]{.de} and found him in deep conversation [(und fand ihn in ein tiefes Gespräch vertieft)]{.de}.

"You could not possibly have come at a better time [(„Sie hätten gar nicht zu einer besseren Zeit kommen können; could not possibly – unmöglich; wörtl.: hätten unmöglich kommen können)]{.de}, my dear Watson," he said cordially [(mein lieber Watson“, sagte er herzlich; cordially – herzlich)]{.de}.
```

---

## 4. The translator brief (paste into each chapter sub-agent)

> You are producing/revising one chapter of a bilingual English→German reader
> (Ilya-Frank style) for a **beginner** learner. The English flows normally; after
> each small chunk a German gloss sits in a span `[(German; notes)]{.de}`.
>
> **GOAL 1 — Natural, idiomatic German.** Translate the *meaning* the way a native
> would say it. Fix wooden word-for-word calques (the worst flaw). Use German
> idioms for English idioms. Correct du/Sie for who is speaking.
>
> **GOAL 2 — Keep generous side-notes.** The `headword – German` notes (plus noun
> genders and irregular verb principal parts) are the main learning value. Keep
> all useful notes; add more freely; only delete a note if factually wrong. Never
> reduce note density.
>
> **GOAL 3 — The bridge rule.** When the natural German diverges from the English
> (reordered, idiomatic, compound word), the note must show what maps to what:
> word-mappings (`very much so – und ob`) and/or a literal `wörtl.: …`. Keep
> chunks small (3–10 English words); split an over-long chunk into two spans, but
> never merge chunks.
>
> **HARD CONSTRAINTS:** Don't change the English text. Don't change chunk
> boundaries except to split. Keep the exact span format `[(...)]{.de}` with plain
> text inside. Keep `# Chapter N · Kapitel N` as line 1. Keep paragraph breaks,
> quotes, em-dashes, letters/blockquotes. German correctness (cases, genders,
> verb forms, word order) is paramount.

---

## 5. Pipeline (step by step)

Working dir convention: **`books/[Book Title]/`** with subdirs `source/`,
`markdown/`, `markdown/parts/`, `build/`, `pdf/`. Downloaded Gutenberg `.txt`
files are cached in **`texts/<Book>/`** (a local cache — re-downloadable, not
committed). Neither `books/` nor `texts/` is committed (see `.gitignore`).

1. **Get the text.** Use the cached `texts/<Book>/pgNNNNN.txt` if present, else
   download it there from gutenberg.org. Identify chapter heading line numbers and
   the `*** END OF THE PROJECT GUTENBERG EBOOK ***` line.
2. **Strip & split.** Remove the Gutenberg header/footer/license. Extract each
   chapter to `source/chNN_raw.txt`.
   - ⚠️ The shell is **zsh** (1-indexed arrays). For index math, run the loop
     under `bash -c '...'` or you'll get an off-by-one.
   - Verify: no `PROJECT GUTENBERG` / `START OF` / `END OF` markers leaked into
     any chapter; the last chapter ends at the story's end, not the license.
3. **Copy the canonical `/build` assets** into `books/<Book>/build/` (they're
   generic) and edit only `build/metadata.yaml` (title/subtitle/author). Build the
   podman image once if it's missing:
   `podman build -t bilingual-book:latest -f build/Containerfile build/`.
4. **Translate via a Workflow** — one sub-agent per chapter, each reads
   `source/chNN_raw.txt`, writes `markdown/chNN.md`, returns a small status
   object (so the big text never bloats the orchestrator). Use the brief in §4.
   Also create `markdown/00-howto.md` (the "how to read" page + a credit line).
   ⚠️ **Do NOT write "Project Gutenberg" (or their header/footer) into the output.**
   "Project Gutenberg" is a trademark; if it appears in the file, the PG license
   attaches and limits redistribution. Use a neutral credit instead, e.g.:
   `*A public-domain text. The German translation and grammar notes were generated
   by AI for language learning; unofficial and may contain errors.*`
   (It's fine to download *from* gutenberg.org — just keep their name out of the book.)
5. **Validate** every chapter:
   - file exists; line 1 is `# Chapter N · Kapitel N`
   - `[(` count == `)]{.de}` count (balanced spans)
   - no stray `[Illustration]` markers (remove them — no images in a text reader)
   - re-run any chapter that came back empty/malformed.
6. **Build PDF and EPUB** (both inside podman):
   - `./build/build-book.sh` → `pdf/[name].pdf`
   - `./build/build-epub.sh` → `pdf/[name].epub`
7. **Spot-check** rendered pages (render a few to PNG with `pdftoppm`, view them):
   title/TOC, a content page, and a page with `wörtl.` bridges and one with
   emphasis-in-gloss.
8. **Report** with honest caveats (it's a machine translation of a whole novel;
   offer quick per-chapter fixes + rebuild).

Optional: do a second **revision pass** (one sub-agent per chapter, reading the
existing EN+DE and improving idiomaticity + adding bridges) if a first pass came
out too literal. That's exactly how this book reached its final quality.

### Single story / short-story collections (e.g. one Sherlock Holmes story)
- Extract just the one story; split it into ~4 even **segments** at blank-line
  (paragraph) boundaries — never cut mid-paragraph, so the seams are invisible.
- Run one sub-agent per segment. Tell each: "MID-STORY SEGMENT — add NO header,
  body paragraphs only." Write to `markdown/parts/partN.md` (a subdir, so the
  build's `markdown/*.md` glob ignores them).
- Assemble: write `markdown/10-story.md` = one title header
  `# English Title · Deutscher Titel` followed by the parts concatenated.
- For a learner who found a previous book too hard, add to the brief: "keep the
  German PLAIN, NATURAL and SPOKEN; short clear sentences." Dialogue-heavy
  short stories are the easiest German.

### The build scripts are now generic (reusable as-is)
`build-book.sh` / `build-epub.sh` derive the book dir from their own location and
include every top-level `markdown/*.md` in sorted order. So: name files for
reading order (`00-howto.md`, `10-story.md`, or `ch01.md`…), copy the whole
`build/` dir to a new book, edit only `metadata.yaml`, and run. No path edits.

---

## 6. The build assets (what's in `build/`, all reusable)

- **`Containerfile`** — arm64 Ubuntu + pandoc + minimal TeX Live + poppler-utils.
  Build once: `podman build -t bilingual-book:latest -f build/Containerfile build/`
  (The official `pandoc/latex` image is **amd64-only** and fails on Apple Silicon —
  that's why we build our own arm64 image.)
- **`de-span.lua`** — turns `[(...)]{.de}` spans into `\textit{\textcolor{germ}{…}}`
  for the **PDF** (LaTeX) only.
- **`pagebreak.lua`** — starts each chapter on a fresh page in the PDF.
- **`grammar-div.lua`** — turns optional `::: grammar … :::` blocks into a framed
  `tcolorbox` in the **PDF**. Harmless (no-op) when a book has no grammar boxes.
- **`header.tex`** — Palatino font (`mathpazo`), gloss colour `germ` (#8A3B2A),
  grammar accent `gramm` (#2F7D6E), `tcolorbox`, line spacing, hyphenation.
- **`metadata.yaml`** — title/subtitle/author (edit per book).
- **`epub.css`** — styles `span.de` for the **EPUB** (brick-red italic; emphasis
  upright) **and** `.grammar` boxes (teal). Note: pandoc emits grammar blocks as
  `<section class="grammar">`, so the CSS targets the **class**, not `div.grammar`.
- **`build-book.sh`** / **`build-epub.sh`** — assemble all chapters → PDF / EPUB
  (both already wire in the grammar filter / CSS; nothing extra to do per book).

Engine notes / gotchas learned:
- PDF uses **pdflatex** (handles ä ö ü ß and dashes/quotes natively; avoids the
  fontspec/xelatex font hassle). `mathpazo` gives the Palatino look without needing
  the TeX Gyre `.sty` files (which the minimal TeX Live lacks).
- **Stray exotic Unicode breaks the pdflatex build** (EPUB is fine — HTML accepts anything). Agents occasionally emit a katakana middle dot `・` (U+30FB) instead of `·`, or a modifier apostrophe `ʼ` (U+02BC). Before/after a failed PDF build, scan the assembled markdown for non-ASCII codepoints and normalize the odd ones to safe equivalents (· `\x{30FB}`→`\x{00B7}`, `\x{02BC}`→`\x{2019}`). Safe set pdflatex+T1 handles: umlauts, ß, æ/œ, é/è/ï/à/ç, – — … „ " ' · . One-liner to enumerate: `perl -CSD -ne 'while(/(.)/g){$c=ord($1);if($c>127){$h{sprintf("U+%04X %s",$c,$1)}++}}END{for(sort keys %h){print "$_ : $h{$_}\n"}}' markdown/story*.md`
- The container's pandoc is older: `--toc=false` is invalid (TOC is off by
  default); EPUB uses `--split-level=1` (not the deprecated `--epub-chapter-level`).
- Each `podman run` is a fresh container — bake tools into the image, don't
  `apt-get` per run.

---

## 7. Tweakables (one-line changes, then rebuild)

- **Gloss colour:** `build/header.tex` (`germ` HTML colour) **and** `build/epub.css`
  (`span.de { color: … }`). Keep them in sync.
- **Kindle / e-ink colour scheme (owner-tested, June 2026).** The default
  brick/teal looks right in print and on LCD, but on e-ink it washes out: a
  colour Kindle (Kaleido panel) renders colour at ~⅓ saturation and 150 ppi,
  so all dark muted tones collapse to the same grey-brown, and on a B&W Kindle
  the brick turns into a muddy mid-grey. Tested side-by-side on a Kindle
  Colorsoft + Paperwhite; the winner ("scheme X") is **pure red German text
  with a blue grammar box** — full-saturation primaries survive the panel,
  red/blue separate the two voices, and both degrade to distinct greys on B&W:
  - `span.de { color: #E10600; font-style: italic; }` (NOT bold)
  - grammar box: border `2px solid #0026E1`, left border `6px`, background
    `#E4E9FC`, heading/em colour `#0026E1` / `#001CB0`
  - **PDF and EPUB must match colour-wise** (owner's rule). Ready-to-swap
    commented blocks for exactly this scheme sit in BOTH `build/epub.css`
    (bottom of file) and `build/header.tex` (the two alternative
    `\definecolor` lines — the PDF derives gloss, box border and box tint
    from just those two). Swap both, rebuild both (`build/build-book.sh` +
    `build/build-epub.sh`, a few minutes).
  - avoid background highlights behind body text (grainy on e-ink, breaks
    night mode) and avoid bold for the whole gloss (too heavy over a novel).
    If the owner reads in night mode, soften the blue to `#3355E0`-style
    mid-tones; pure `#0026E1`/dark colours go dim on black.
- **Font / size / leading:** `build/header.tex` (`mathpazo`, `\setstretch`) and
  `-V fontsize` in the build scripts; `body { font-family … }` in `epub.css`.
- **Margins:** `-V geometry:"margin=2.4cm"` in `build-book.sh`.
- **Note density / chunk size / register:** adjust the brief in §4.

---

## 8. Quick reference — the one-liner to give Claude next time

> "New bilingual reader: **[Title]**, Gutenberg [URL]. Follow `instruction.md` —
> English base, German in parens, generous side-notes + `wörtl.` bridges,
> idiomatic German, du/Sie correct. Put it in `books/[Title]/`, do PDF + EPUB,
> all in podman. Skip the proof step; go straight to the full book.
> Grammar: **[none]** or **[level range, e.g. A1–A2]**."

When the request names a grammar level, also do §9. If grammar isn't mentioned,
ask once ("grammar interludes? if so, what CEFR level — or none?") then proceed.

For the latest preferred learning mode:

> "New German-first read-aloud reader: **[Title]**, Gutenberg [URL]. Follow
> `CLAUDE.md` and `instruction.md`. Use the German-first format, EPUB3 Media
> Overlays for Apple Books fixed-layout and BookFusion reflowable, ElevenLabs
> `eleven_flash_v2_5`, cached per-chapter audio, and do not regenerate any cached
> chapter unless I ask."

---

## 9. Grammar interludes (optional feature)

Grammar is **opt-in**. If the owner doesn't want it, do nothing here — the book is
the clean bilingual format. If they do, weave in short **grammar boxes**.

**Ask first (if not specified):** *"Grammar interludes — and at what CEFR level
range (e.g. A1–A2, A2–B1, or wide A1–B1)? Or none?"* The level chooses the
curriculum; everything else is automatic.

**Format — one source, both outputs.** A box is a pandoc fenced div:

```
::: grammar
#### Grammar — der, die, das: nouns have a gender
Look at the articles in the notes: *der* Herr, *die* Tür, *das* Sofa. Every German
noun is masculine/feminine/neuter — learn each noun **with** its article …
:::
```

→ EPUB: `<section class="grammar">` (teal box via `epub.css`); PDF: framed
`tcolorbox` (via `grammar-div.lua`). One grammar point per box; short; written in
English with German examples in *italics* (NOT `.de` spans — boxes are meta).

**Contextual anchoring (the important bit).** Each box teaches a point that *just
appeared* in the nearby text ("you just saw *X* — here's the rule"). Place boxes at
paragraph/scene/chapter breaks, never mid-paragraph, never inside a `.de` span.

**Pacing & the length check.**
1. Build the plain book first (or estimate) to get the **page count** `P`.
2. Target **one box every 3–7 pages**. Max boxes that fit ≈ `P / 3`.
3. Take the **curriculum** `C` for the chosen level (ordered list, below). Let
   `K = len(C)`.
   - If `K ≤ P/3`: place all `K`, spaced evenly at `P/K` pages (clamp display
     pace into the 3–7 range; if `P/K > 7`, that's fine — just fewer, wider boxes).
   - If `K > P/3`: **the book is too short** to cover the level at a sane pace.
     **Tell the owner**, then cover the first `floor(P/3)` points (the curriculum
     is ordered, so this is the natural prefix), and say which points were left out.
4. Implementation: after assembling chapters, insert boxes at the chosen break
   points — a sub-agent reads the text around each target position and writes a box
   for the next curriculum point, anchored to a real nearby sentence.

**Example curricula (ordered; trim/extend as fits):**
- **A1–A2:** verb-second word order · der/die/das & gender · Sie vs du · present
  tense & sein/haben · nominative vs accusative · plural formation · negation
  (nicht/kein) · modal verbs · perfect tense (haben/sein + participle, verb-final)
  · possessives · prepositions + accusative/dative.
- **A2–B1:** dative case & verbs · two-way prepositions · separable verbs ·
  reflexive verbs · adjective endings · comparative/superlative · subordinate
  clauses (verb-final, *weil/dass/wenn*) · Präteritum · genitive · relative
  clauses · future tense.
- **A1–B1 (wide):** merge the two, lighter and more spread out.

**Verify** after building: grammar boxes render (teal in EPUB, framed in PDF), sit
at breaks (not inside `.de` spans), and don't break span balance.

---

## 10. Wortbildung & Etymologie notes (optional feature; owner-approved format, June 2026)

A second optional layer besides grammar boxes. The owner approved this format
from a built sample (Dracula ch. 1 opening); follow it exactly.

**A. Compound joints (Wortbildung) — in the regular side-notes, throughout.**
German compounds and derivations get their seams marked with a raised dot `·`
(U+00B7, pdflatex-safe) plus the building blocks:
- compounds: `the station – der Bahnhof = Bahn·hof: die Bahn (railway) + der Hof (yard)`
- suffix derivations are equally valuable: `die Verspätung = Ver·spät·ung, von
  spät (late); die Endung -ung macht Verben zu Substantiven, immer mit die` —
  point out productive endings when first met: `-ung` (→ die), `-bar` (= -able),
  `-schaft` (= -ship), `-lich`, `-heit/-keit`, `un-`.
- The intro page (00-about/howto) must state: the dot is the book's marker only;
  real German spells the word solid (*Bahnhof*).
- Do every compound worth cracking; these are cheap and the owner (a beginner
  who cannot yet see the seams) explicitly wants them.

**B. Separable verbs — marked `(trennbar)` with a split example, throughout.**
`to depart – abfahren = ab·fahren (trennbar: der Zug fährt … ab)`. The split
example (`fährt … ab`) is the point — show where the prefix lands.

**C. Etymology notes — `Etym.:` prefix, GERMAN words only.**
Explain why the German word means what it means (the picture hiding inside it):
*vielleicht = viel·leicht "very easily"*, *Kellner from Keller*, *begreifen from
greifen*, *der Augenblick = "a glance of the eye"*. NEVER explain English words'
histories (owner decision — he reads English etymology elsewhere; an early
sample had `breakfast = break + fast` and was corrected).
- **Density:** 1–2 per page, only where the story is genuinely good.
- **Language ramps with the reader (owner decision).** Split the book into
  thirds by chapter:
  - first third — Etym. notes written in **English**;
  - middle third — **simple German with inline English glosses** on any
    non-beginner word, i.e. the note itself is Ilya-Frank-ified:
    `Etym.: vom Keller (cellar) – ursprünglich (originally) der Diener, der den
    Weinkeller verwaltete (managed)`;
  - final third — **plain simple German** (A2-level wording, short sentences).
  State the phase boundaries in the translator briefs so sub-agents comply.

**D. Wortbildung boxes.** Occasionally (every ~15–25 pages) a box via the same
`::: grammar … :::` machinery, heading `#### Wortbildung — <topic>`, stepping
back to show a pattern ("read compounds from the right; the last piece owns the
gender"), always anchored to words just read. These count toward box pacing but
NOT toward the grammar curriculum count.

**E. When combined with grammar interludes (§9):** keep both; grammar boxes
follow the curriculum, Wortbildung boxes are extra. For a long book (e.g.
Dracula, ~736 pp. bilingual) one box per ~6–7 pages total fits the full A1–B1
curriculum plus reviews plus Wortbildung boxes comfortably.

**Candidate extras the owner has seen and may request:** false-friend warnings
(eventuell ≠ eventually), chapter-end vocab recap boxes, plural forms for
irregular nouns in notes (der Traum, pl. die Träume — already in use).

---

## 11. Einbürgerungstest edition — exam boxes + verb spotlights (owner-approved, 2026)

The owner wants the readers to double as **naturalization-exam ("Leben in Deutschland" / Einbürgerungstest) prep**. A combined edition carries everything the grammar/Wortbildung edition has PLUS:

- **~54 "Verb im Fokus" spotlights** — full conjugation of key strong/irregular verbs, written as ordinary `::: grammar` boxes (blue) with the heading `#### Verb im Fokus — <verb>`.
- **Exam clusters** — a **third box category**, `::: ebt`, rendered **green**, one cluster per chapter (~11–12 questions), bilingual (German Q + 4 options, correct marked `✓`, English gloss + short vocab note). ~300 federal questions distributed ch1 = Fragen 1–12, then ~11/chapter; the 10 Bundesland questions append to the last chapter.

**Machinery (reproduce exactly):**
- `grammar-div.lua` handles BOTH `::: grammar` (blue) and `::: ebt` (green), plus `breakable` so long clusters split across PDF pages. `epub.css` has matching `.ebt` rules.
- **`header.tex` for an exam edition MUST declare** (the generic `/build` header does NOT — this is the #1 build failure):
  - `\definecolor{ebt}{HTML}{1B6B3A}`
  - `\DeclareUnicodeCharacter{2192}{$\rightarrow$}`  (the → used in notes)
  - `\DeclareUnicodeCharacter{2713}{\checkmark}`  (the ✓ on correct answers)
  - **⇒ SHORTCUT: for any new exam book, copy the whole `build/` from an existing exam book** (`books/Dracula (A1-B1 + Verben + Test)/build/`) instead of the generic `/build` — it already has ebt colour, ✓, →, and the current gray scheme. Copying only the generic `/build` will fail the PDF at the first ✓.
- **NEVER** use emoji or markdown strikethrough `~~…~~` in boxes — `~~` pulls in `soul.sty`, which the minimal TeX image lacks and which breaks the PDF (EPUB is unaffected). Show a wrong form as `*form* (falsch)` instead.
- Exam clusters are rendered **deterministically by a script from verified JSON** — no LLM re-handles the answer keys. Sourcing method: fetch `lebenindeutschland.eu/fragenkatalog/{1..10}` (30 Q/page = 300 federal) + `/fragenkatalog/{statecode}` for the 10 state questions (Berlin = `be`); then a **second agent independently answers each question to cross-verify** the key. Catalogue = 300 federal + 10/state; the real test is 33 Q, pass = 17.
- **Picture-dependent questions** (Wappen, flags, zone maps, ballot images — e.g. federal Q55/130/176/209, and 2 per Bundesland) can't render in a text book. **Reword them as an equivalent text question** testing the same fact (e.g. "Welches Tier zeigt das Wappen Berlins?" → Bär), and add a note that the real exam shows a picture. Only substitute a fact you are certain of; grep the whole book to be sure the replacement question isn't already used elsewhere.
- Owner's **Bundesland is Berlin** — the 10 Berlin questions live at the end of ch27; verified data cached at `texts/Einbuergerungstest/berlin-be.json`.

## 12. Current colour scheme — GRAY e-ink (supersedes the red/blue of §7)

After more e-ink testing the owner settled on **dark-gray gloss** (not red), keeping grammar blue and adding exam green. This is the CURRENT default; the canonical `/build` now carries it:
- gloss `germ` = **`#555555`** (dark gray), `span.de { color:#555555 }`
- grammar box blue `#0026E1` (heading/em `#001CB0`)
- exam box green `ebt` `#1B6B3A` (epub `.ebt` `#14532D`)
- PDF + EPUB must still match (owner's standing rule). Reads well on B&W and colour Kindles; gray gloss is calm under a whole novel.

## 13. Reviewing / fixing an already-built book (review → fix → verify loop)

Machine translation of a whole novel lands ~7.5/10; a fix pass gets it to ~9. Pattern that works (survives session-limit interruptions because every step's output is a file on disk):
1. **Review:** one reviewer sub-agent per chapter (run several in parallel), each returns a compact findings list (severity-ranked). Sample first to get the error *rate*, then go full-coverage for the actual fixes.
2. **Write per-chapter fix-list files** to scratchpad (`findings/chapNN.md`), one shared `FIXER-INSTRUCTIONS.md`, and give each fixer a tiny prompt: "follow FIXER-INSTRUCTIONS, chapter = X, fix-list = Y". Use **`model: "opus"`** on the sub-agents for quality (and to spare the main-session/Fable budget).
3. **Systematic defect classes to ALWAYS lint** (these recur in every machine-translated book): (a) `·` compound-joint notation wrongly applied to ENGLISH words — joints are for German words only; (b) reversed note order `German – English` (should be `English headword – German`) — clusters in the *second half* of chapters where a different segment-agent drifted; (c) **du/Sie seam breaks** — a character (esp. Van Helsing) flips register mid-scene where independently-translated segments were concatenated; fix with a per-book character-pair register table; (d) fake `= word` derivations that decompose a *different* word than the equivalent given; (e) false etymologies (verify every `Etym.:` — the Wortbildung layer is historically the weakest); (f) picture-dependent exam questions.
4. **Verify:** after fixing, re-read a sample of the riskiest chapters with fresh sub-agents (checklist + damage-hunt + spot-translation). Catches missed fixes and any new damage.
5. **Interruptions:** subagents that die (session limit / connection) are re-runnable — completed chapters are files, so just relaunch the failed ones; a fixer that finds its fix already applied reports "already-done".
6. **Always archive `pdf/*.{pdf,epub}` into `pdf/archive/` with a version-date suffix BEFORE rebuilding** — a rebuild silently overwrites, and the owner wanted the prior version kept.

## 14. German-first ("Deutsch zuerst") flipped edition

The owner learns fastest reading **German as the base text** (English-first is training wheels; German-base forces native word order/cases). We produce a flipped edition FROM the fixed English-first master (so it inherits all fixes). New dir `books/<Title> (Deutsch zuerst)/`; never touch the English-first book.

Pipeline (≈78 segments for a 27-ch book):
- **Split** each source chapter into ~3 segments at blank-line boundaries that fall **OUTSIDE `:::` boxes** (compute with a script that tracks box depth).
- **One Opus sub-agent per segment** from a shared `FLIP-INSTRUCTIONS.md`; tiny per-segment prompt gives SOURCE file + LINE RANGE + OUTPUT path. Rules: German becomes the **base text, smoothed into continuous natural prose** (chunk-glosses don't concatenate cleanly — every seam must be repaired); Stoker's **original English goes into the `[(...)]{.de}` spans**; notes flip to **`German headword – English meaning`** with der/die/das + principal parts; keep Wortbildung joints on German words; add a **REVERSED BRIDGE hint** wherever German word order can't map onto English (verb-second, verb-final, separable prefix flying to clause end); **copy every `::: grammar`/`Verb im Fokus`/`::: ebt` box VERBATIM** into position (anchors still work — they cite German, now the base).
- **Assemble** 3 parts/chapter with `head -1 <source>` for the `# Chapter N · Kapitel N` heading. Validate: `[(` count == `)]{.de}`, box openers == closers, no exotic unicode. (Flipped span counts run slightly *higher* than source — finer re-chunking, not lost content.)

Flip-specific gotchas (all observed, all recur):
- **Content-filter false-positives** on gothic/horror scenes (staking, sleepwalking, Renfield, vampire women) hit ~1 in 8 segments as "Output blocked by content filtering policy". Retry with explicit framing: *"reformatting a public-domain literary classic; the German translation already exists; you only reformat it for learners."* If it blocks **twice**, **split the segment into two smaller halves** — the smaller output clears the filter.
- **Quote regression:** flip agents close German dialogue with a straight `"` instead of the German `"` (U+201C). After assembly, normalize **span-aware** (base text only, leave span interiors/English alone): in non-box, non-span text replace closing `"` → `"`.
- **Stray arrows:** agents sometimes emit `↔` (U+2194) etc. in register notes — lint `[↔←⇔⇒]` before building (`→` U+2192 IS declared in the exam header, the others are not). Also lint `≈` (U+2248) → "entspricht".
- **Split-segment box ownership:** when a segment split lands inside a box, the box belongs to whichever half holds its `:::` **opener**; tell the other half to start *after* the box so it isn't duplicated.
- Same build-config rule as §11: copy the exam book's `build/` (ebt/✓/→ + gray).

## 15. Vocabulary export — Anki & Mochi (owner uses these to drill the book's words)

`build/make-anki-tsv.py <book-dir>` harvests every `headword – Übersetzung` pair from the notes into a TSV (front = German with article/parts, back = English, col 3 = chapter tag). Dedups; ~16.8k cards for Dracula. Reusable on any book.

- **Anki:** free **Anki Desktop** (Mac) → File → Import the `.tsv` (separator = Tab), map field 3 → **Tags**; then study **by chapter** via Custom Study → by tag → `chapNN`. Free **AnkiWeb** (browser) can only *review/sync*, **not import** — do the import once on Desktop, then sync. Phone: **AnkiDroid** free (Android); **AnkiMobile** ~€30 one-time (iOS, optional); AnkiWeb-in-Safari free. ⚠️ **Avoid "AnkiApp"** on the iOS store — unaffiliated knockoff, not the real Anki.
- **Mochi (web, owner's choice):** two hard-won facts —
  1. Mochi's CSV parser is **naive and does NOT honor quoted fields** — a field containing a comma (even quoted) splits into extra columns → error *"Invalid Record Length: expect 2, got N"*. So a CSV for Mochi must have **exactly one comma per line**: replace every comma *inside* a field with `;` (e.g. `keep, kept, kept` → `keep; kept; kept`), no BOM, no header. AND import into a deck with **NO template** (a templated target deck maps columns by header name, finds none, and yields **empty cards** — the classic symptom).
  2. **Most reliable = native `.mochi`** (owner-confirmed working): a ZIP containing one `data.edn` file. Structure: `{:version 2 :decks [{:name "Dracula Kap. 01" :cards [{:content "FRONT\n\n---\n\nBACK"} …]}]}`. Two musts: (a) **use REAL newline characters** in the `:content` string, NOT the `\n` escape — Mochi prints `\n` literally and then the divider never lands on its own line; (b) front/back are split by **`---` on its own line** (Mochi's convention; the doc calls `:content` just "the contents of the card" and does not document the divider, but `---` works). One `.mochi` with all chapters as separate decks = one import, organized by chapter.

## 16. Read-aloud EPUB3 Media Overlay workflow (latest audio direction, July 2026)

This is the owner's preferred pronunciation/listening setup after live testing
on iPad Pro. It is **not conceptually Dracula-only**: use it for future
German-first books too. Current caveat: the working scripts were first created
inside `books/Dracula (Deutsch zuerst)/scripts/`, so for another book either copy
those scripts into that book's `scripts/` directory or promote them to a shared
repo-level location before use.

### Decisions already settled

- Target apps:
  - **Apple Books on iPad**: use fixed-layout EPUB 3 Media Overlays. Sync works,
    but pages behave like PDF pages and font controls are limited.
  - **BookFusion**: use reflowable EPUB 3 Media Overlays. Sync works, with normal
    EPUB font controls.
- Do **not** target Kindle/Paperwhite/Kindle iOS for custom synced audio. Kindle
  can still be used for ordinary EPUB reading, but it is not a synced read-aloud
  target.
- Audio provider: **ElevenLabs API**.
- Default model: **`eleven_flash_v2_5`**. The owner compared it with
  `eleven_multilingual_v2` and could not hear a downside; Flash was at least as
  clear and is cheaper.
- Default output format: `mp3_44100_128`.
- Voice can vary by book; for Dracula the tested voice was
  `g1jpii0iyvtRs8fqXsd1`.
- Key file: repo-root `.elevenlabs.env` with `ELEVENLABS_API_KEY` and optionally
  `ELEVENLABS_VOICE_ID`. **Never print the key. Never commit it.**
- Generated audio/timing files are cache artifacts. **Never regenerate a cached
  chapter unless the owner explicitly asks**, because regeneration spends
  credits again and may change timing/voice performance.

### Directory convention

Inside a German-first book directory such as `books/<Title> (Deutsch zuerst)/`:

```text
german-only/
  ch01.txt                      clean German-only text for TTS
audio-elevenlabs-timed/
  ch01/
    manifest.json               chapter cache manifest
    ch01-part001.mp3            cached audio chunk
    ch01-part001.json           cached text + character timing
    ...
media-overlay-books/
  <title>-readaloud-ch01.epub              Apple Books fixed-layout read-aloud EPUB
  <title>-readaloud-reflowable-ch01.epub   BookFusion reflowable read-aloud EPUB
scripts/
  extract_german_only.py
  elevenlabs_timed_chapter.py
  build_media_overlay_epub.py
```

The cache is per chapter. To add chapter 2 later, generate only `ch02`, then
rebuild a combined EPUB from `ch01 ch02`. Chapter 1 is reused from cache and is
not sent to ElevenLabs again.

### Standard commands

From the book directory:

```sh
# 1. Extract clean German-only text from German-first markdown.
python3 scripts/extract_german_only.py

# 2. Estimate cost/chunks. This does NOT call ElevenLabs.
python3 scripts/elevenlabs_timed_chapter.py ch02 --dry-run

# 3. Generate cached audio + character timestamps.
set -a; source ../../.elevenlabs.env; set +a
python3 scripts/elevenlabs_timed_chapter.py ch02

# 4. Build both EPUB variants from cached chapters only.
python3 scripts/build_media_overlay_epub.py ch01 ch02 --layout fixed
python3 scripts/build_media_overlay_epub.py ch01 ch02 --layout reflowable
```

If running from this Codex environment, network calls to ElevenLabs require user
approval because they spend credits. State the submitted character count before
requesting approval.

### What the scripts do

- `elevenlabs_timed_chapter.py`
  - Uses ElevenLabs `POST /v1/text-to-speech/:voice_id/with-timestamps`.
  - Splits the chapter into safe chunks.
  - Writes one `.mp3` plus one `.json` per chunk under
    `audio-elevenlabs-timed/<chapter>/`.
  - Writes `manifest.json` with `model_id`, `voice_id`, character count, chunk
    list, and source hashes.
  - Refuses to overwrite a matching cache unless `--overwrite` is passed.

- `build_media_overlay_epub.py`
  - Reads only cached `audio-elevenlabs-timed/<chapter>/manifest.json` data.
  - `--layout fixed`: builds an Apple Books version with one XHTML page and one
    SMIL overlay per fixed page, plus the cached MP3 chunks.
  - `--layout reflowable`: builds a BookFusion version with one XHTML document
    and one SMIL overlay per chapter, plus the same cached MP3 chunks.
  - Supports multiple chapters in one command, e.g. `ch01 ch02 ch03`.
  - Does not call ElevenLabs and does not spend credits.

### Current Dracula facts (for continuity only)

- `ch01` was generated before the Flash default changed, using
  `eleven_multilingual_v2`, 34,597 submitted characters, 9 chunks, about 42
  minutes of audio. Keep it unless the owner asks for model consistency.
- Future Dracula chapters default to `eleven_flash_v2_5`.
- Apple Books did **not** play the reflowable sample, but did play the
  fixed-layout sample beautifully.
- BookFusion did play the reflowable sample and gives normal font controls.

### Fresh-session checklist

If the owner returns in a new session and says "continue the audio/read-aloud
book", do this:

1. Read `CLAUDE.md` and this section.
2. Check which chapters already have
   `audio-elevenlabs-timed/<chapter>/manifest.json`.
3. Dry-run only the next missing chapter to show character count.
4. Ask approval before any ElevenLabs generation.
5. Build/rebuild both combined EPUB variants from all cached chapters.
6. Report exactly which chapters were reused and which were newly generated.
