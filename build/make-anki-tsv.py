#!/usr/bin/env python3
"""Harvest vocabulary notes from an Ilya-Frank bilingual book into an Anki-importable TSV.

Usage:  python3 make-anki-tsv.py <book-dir> [out.tsv]

Scans <book-dir>/markdown/chap*.md (or story*.md), pulls every
`English headword – German equivalent` pair out of the [(...)]{.de} spans,
dedupes (first occurrence wins; its chapter becomes the card's tag), and
writes a 3-column TSV:  front (German), back (English), tags (chapter).

Import in Anki: File > Import, type "Notes in Plain Text", field separator Tab,
map col1->Front, col2->Back, col3->Tags. Front shows the German (with article/
principal parts), back the English — recognition direction for reading fluency.
Skips wörtl./Etym./register/grammar comments and Wortbildung joint analyses.
"""
import re, sys, csv, glob, os

book = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(book, "anki-vocab.tsv")

SPAN = re.compile(r"\[\((.*?)\)\]\{\.de\}", re.S)
# note item: "english headword – german stuff" (en dash). English side: latin letters,
# apostrophes, hyphens, spaces, may start with "to " or "the ".
PAIR = re.compile(r"^(?:to |the |a )?([A-Za-z][A-Za-z' ,.\-()/]{1,40}?)\s+–\s+(.+)$")
SKIP = re.compile(r"wörtl\.|Etym\.|hier:|word order|trennbar\)|„|Verb-|=", re.I)

seen, rows = set(), []
files = sorted(glob.glob(os.path.join(book, "markdown", "chap*.md")) +
               glob.glob(os.path.join(book, "markdown", "story*.md")))
for f in files:
    tag = os.path.splitext(os.path.basename(f))[0]
    text = open(f, encoding="utf-8").read()
    for span in SPAN.findall(text):
        # notes come after the first ';' — the part before is the translation
        parts = span.split(";")[1:]
        for p in parts:
            p = p.strip()
            if not p or SKIP.search(p):
                continue
            m = PAIR.match(p)
            if not m:
                continue
            eng, ger = m.group(1).strip(), m.group(2).strip()
            # german side must actually contain german-ish content
            if not re.search(r"[a-zäöüß]", ger) or len(ger) > 120:
                continue
            key = (eng.lower(), ger.lower())
            if key in seen:
                continue
            seen.add(key)
            rows.append((ger, eng, tag))

with open(out, "w", encoding="utf-8", newline="") as fh:
    w = csv.writer(fh, delimiter="\t")
    for ger, eng, tag in rows:
        w.writerow([ger, eng, tag])
print(f"{len(rows)} unique cards -> {out}")
