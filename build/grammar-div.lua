-- Optional grammar interludes. A pandoc fenced div `::: grammar … :::` becomes:
--   * EPUB/HTML: <section class="grammar"> (styled by .grammar in epub.css)
--   * PDF/LaTeX: a framed tcolorbox (this filter)
-- Harmless when a book has no grammar boxes.
function Div(el)
  if el.classes:includes("grammar") and FORMAT:match("latex") then
    local out = {}
    table.insert(out, pandoc.RawBlock("latex",
      "\\begin{tcolorbox}[colback=gramm!4,colframe=gramm,boxrule=0.6pt,arc=2pt,left=6pt,right=6pt,top=4pt,bottom=4pt]"))
    for _, b in ipairs(el.content) do table.insert(out, b) end
    table.insert(out, pandoc.RawBlock("latex", "\\end{tcolorbox}"))
    return out
  end
end
