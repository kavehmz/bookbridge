-- Turn pandoc spans with class "de" into colored, italic German glosses.
-- Works for the LaTeX/PDF writer. Keeps the inner content (which pandoc has
-- already escaped) and wraps it in \textit{\textcolor{germ}{...}}.
function Span(el)
  if el.classes:includes("de") then
    local out = {}
    table.insert(out, pandoc.RawInline("latex", "\\textit{\\textcolor{germ}{"))
    for _, inl in ipairs(el.content) do
      table.insert(out, inl)
    end
    table.insert(out, pandoc.RawInline("latex", "}}"))
    return out
  end
end
