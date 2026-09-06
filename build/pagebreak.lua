-- Start every chapter (level-1 header) on a fresh page, except the first.
local first = true
function Header(el)
  if el.level == 1 then
    if first then
      first = false
      return el
    end
    return { pandoc.RawBlock("latex", "\\clearpage"), el }
  end
end
