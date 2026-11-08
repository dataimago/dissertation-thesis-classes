-- thesis-divs.lua -- Pandoc/Quarto filter for the dataimago-thesis class (house class, step 2)
-- Copyright 2026 dataimago. Distributed under the LaTeX Project Public License
-- 1.3c or later (https://www.latex-project.org/lppl/). Maintainer: dataimago.
-- Version: 2026/11/08 v0.1.0
--
-- What it does (docs/house-class-spec.md R8-R10, R5, A2):
--   * PDF only: lifts the divs .dedication .acknowledgments .preface .abbreviations .symbols
--     whose page id is in frontmatter.order into metadata (thesis-front.<id>) and removes them
--     from the body; a host chapter left empty is dropped. HTML output is left untouched (R9).
--   * Warns (quarto.log.warning) for every Quarto key the profile replaces (R10).
--   * Derives thesis-derived.{year,month-year,type} from the date and degree, logging each default (R5).
--   * Enforces alt text on images per accessibility.altTextEnforcement (A2).
--   * Sets indent=true so Pandoc's own parskip handling stays out of the class's paragraph style.
local function script_dir()
  local f = PANDOC_SCRIPT_FILE or ""
  return (f:match("^(.*)[/\\][^/\\]*$")) or "."
end

local function warn(msg)
  if quarto and quarto.log and quarto.log.warning then quarto.log.warning("dataimago-thesis: " .. msg)
  else io.stderr:write("WARNING dataimago-thesis: " .. msg .. "\n") end
end
local function info(msg)
  if quarto and quarto.log and quarto.log.info then quarto.log.info("dataimago-thesis: " .. msg)
  else io.stderr:write("INFO dataimago-thesis: " .. msg .. "\n") end
end

local function str(v) return v and pandoc.utils.stringify(v) or nil end

-- read profiles/<id>.cfg (generated; one \ThesisCfg{key}{value} per line)
local function read_cfg(id)
  local dirs = {}
  local env = os.getenv("THESIS_PROFILES_DIR")
  if env and env ~= "" then dirs[#dirs+1] = env end
  local sd = script_dir()
  dirs[#dirs+1] = sd .. "/../../profiles"
  dirs[#dirs+1] = sd
  dirs[#dirs+1] = "profiles"
  dirs[#dirs+1] = "."
  for _, d in ipairs(dirs) do
    local f = io.open(d .. "/" .. id .. ".cfg", "r")
    if f then
      local cfg = {}
      for line in f:lines() do
        -- the final } is the pattern's own, so the captured value excludes it
        local k, v = line:match("^\\ThesisCfg{([^}]*)}{(.*)}$")
        if k then cfg[k] = v end
      end
      f:close()
      return cfg
    end
  end
  return nil
end

-- Quarto/Pandoc keys the profile replaces (R10): key -> replacement
local REPLACED = {
  geometry = "geometry.* (margins, paper, binding)", mainfont = "type.main", sansfont = "type.sans",
  monofont = "type.mono", mathfont = "type.math", fontsize = "type.size", linestretch = "spacing.body",
  papersize = "geometry.paper", toc = "frontmatter.order", lof = "frontmatter.order",
  lot = "frontmatter.order", ["toc-depth"] = "toc.depth", colorlinks = "submission.links",
  linkcolor = "submission.linkColor", urlcolor = "submission.linkColor", citecolor = "submission.linkColor",
  pdfstandard = "submission.pdfa / accessibility.pdfua",
}
-- Quarto injects some of these itself (toc: true on books, colorlinks: true, linkcolor: blue,
-- papersize: letter); a value equal to Quarto's own default cannot be told from no value, so it
-- is not reported. Anything the author changes is.
local QUARTO_DEFAULT = { toc = "true", colorlinks = "true", linkcolor = "blue", papersize = "letter" }

-- keys Pandoc's own templates would act on (geometry clashes with the class; babel-lang.tex would load mainfont)
local DROPPED = { geometry = true, linestretch = true, mainfont = true, sansfont = true, monofont = true, mathfont = true, fontsize = true, papersize = true }

-- Quarto consumes toc, lof, lot and toc-depth itself, so they never reach doc.meta; read them from the
-- project files (_quarto.yml and the active profile files) instead.
local FILE_KEYS = { "toc", "lof", "lot", "toc-depth" }
local function project_yaml_keys()
  local dir = (quarto and quarto.project and quarto.project.directory) or "."
  local files = { dir .. "/_quarto.yml" }
  for prof in (os.getenv("QUARTO_PROFILE") or ""):gmatch("[^,]+") do
    files[#files+1] = dir .. "/_quarto-" .. prof .. ".yml"
  end
  local found = {}
  for _, f in ipairs(files) do
    local h = io.open(f, "r")
    if h then
      local text = h:read("a"); h:close()
      local ok, d = pcall(pandoc.read, "---\n" .. text .. "\n---\n", "markdown")
      if ok then
        for _, k in ipairs(FILE_KEYS) do
          local fmt = d.meta.format and d.meta.format.pdf
          if d.meta[k] ~= nil or (fmt and fmt[k] ~= nil) then found[k] = f end
        end
      end
    end
  end
  return found
end

local PROSE = { "dedication", "acknowledgments", "preface", "abbreviations", "symbols" }

local function in_order(order, id)
  for item in (order or ""):gmatch("[^,]+") do if item == id then return true end end
  return false
end

local MONTHS = { January=1, February=2, March=3, April=4, May=5, June=6, July=7, August=8,
  September=9, October=10, November=11, December=12 }
local MONTHNAMES = { "January", "February", "March", "April", "May", "June", "July", "August",
  "September", "October", "November", "December" }

local function derive_date(d)
  if not d or d == "" then return nil, nil end
  local y, m = d:match("(%d%d%d%d)-(%d%d)")
  if y then return y, MONTHNAMES[tonumber(m)] .. " " .. y end
  y = d:match("(%d%d%d%d)")
  for name in pairs(MONTHS) do
    if d:find(name, 1, true) then return y, name .. " " .. (y or "") end
  end
  return y, y
end

local function check_images(doc, enforcement)
  if enforcement == "off" then return end
  doc.blocks:walk({
    Image = function(img)
      local alt = img.attributes["fig-alt"] or img.attributes["alt"]
      if not alt or alt == "" then
        local msg = "figure '" .. img.src .. "' has no alt text (set fig-alt)"
        if enforcement == "warn" then warn(msg) else error("dataimago-thesis: " .. msg, 0) end
      end
    end,
  })
end

function Pandoc(doc)
  local is_pdf = FORMAT:match("latex") or FORMAT:match("pdf") or (quarto and quarto.doc and quarto.doc.is_format and quarto.doc.is_format("pdf"))
  if not is_pdf then return nil end -- R9: HTML keeps the divs and the host chapter

  local meta = doc.meta
  local thesis = meta.thesis or pandoc.MetaMap({})
  local profile = str(thesis.profile)
  if not profile or profile == "" then
    profile = "house"
    info("thesis.profile is not set; using the default 'house'")
  end
  local cfg = read_cfg(profile)
  if not cfg then
    error("dataimago-thesis: no profile file " .. profile .. ".cfg found (looked next to the filter, in ../../profiles and in ./profiles). Set thesis.profile in _quarto.yml to a profile that exists.", 0)
  end

  -- R10: unsupported Quarto keys
  for key, replacement in pairs(REPLACED) do
    local v = meta[key]
    if v ~= nil and str(v) ~= QUARTO_DEFAULT[key] then
      warn("'" .. key .. "' is ignored; set " .. replacement .. " in the profile (profiles/" .. profile .. ".yaml)")
      -- keys Pandoc's own template would act on (geometry would option-clash with the class) are dropped
      if DROPPED[key] then meta[key] = nil end
    end
  end
  for key, file in pairs(project_yaml_keys()) do
    warn("'" .. key .. "' is ignored; set " .. REPLACED[key] .. " in the profile (profiles/" .. profile .. ".yaml); found in " .. file:match("[^/]*$"))
  end
  local dc = meta.documentclass and str(meta.documentclass)
  if dc and dc ~= "dataimago-thesis" then
    warn("'documentclass: " .. dc .. "' is ignored; the house class is always loaded and the institution is chosen by thesis.profile")
  end

  -- R5: defaults, logged once each
  local date = str(meta.date) or ""
  local year, monthyear = derive_date(date)
  if not thesis.year then info("thesis.year is not set; using " .. tostring(year) .. " from the date") end
  if not thesis.type then
    local dn = str(thesis.degree and thesis.degree.name) or ""
    local t = (dn:lower():find("master") or dn:lower():find("bachelor")) and "thesis" or "dissertation"
    meta["thesis-derived"] = pandoc.MetaMap({ type = pandoc.MetaString(t) })
    info("thesis.type is not set; using '" .. t .. "' from the degree name")
  else
    meta["thesis-derived"] = pandoc.MetaMap({ type = pandoc.MetaString(str(thesis.type)) })
  end
  local derived = meta["thesis-derived"]
  derived.year = pandoc.MetaString(year or "")
  derived["month-year"] = pandoc.MetaString(monthyear or year or "")
  if not meta.lang then info("lang is not set; using 'en-US'") end

  -- A2: alt text
  check_images(doc, cfg["accessibility.altTextEnforcement"] or "error")

  -- which lists will have entries: a captioned table is a Quarto float (FloatRefTarget around a Table)
  -- or a Table with a long caption; a captioned figure is a FloatRefTarget without a Table, or a captioned Figure
  local has_lot, has_lof = false, false
  doc.blocks:walk({
    Table = function(t) if #t.caption.long > 0 then has_lot = true end end,
    Figure = function(f) if #f.caption.long > 0 then has_lof = true end end,
    Div = function(d)
      if d.attributes["__quarto_custom_type"] == "FloatRefTarget" then
        local table_inside = false
        d:walk({ Table = function() table_inside = true end })
        if table_inside then has_lot = true else has_lof = true end
      end
    end,
  })
  derived["has-lot"] = pandoc.MetaString(has_lot and "1" or "0")
  derived["has-lof"] = pandoc.MetaString(has_lof and "1" or "0")

  -- R8: lift prose divs
  local order = cfg["frontmatter.order"] or ""
  local lifted = {}
  local lifted_count = 0
  local function lift(div)
    for _, id in ipairs(PROSE) do
      if div.classes:includes(id) then
        if not in_order(order, id) then
          if #div.content > 0 then
            warn("the '." .. id .. "' div is not printed: '" .. id .. "' is not in frontmatter.order of profile " .. profile .. "; it stays in the body where you wrote it")
          end
          return nil
        end
        lifted[id] = lifted[id] or {}
        for _, b in ipairs(div.content) do lifted[id][#lifted[id]+1] = b end
        lifted_count = lifted_count + 1
        return {}
      end
    end
    return nil
  end

  -- process top-level sections so an emptied host chapter can be dropped
  local blocks = doc.blocks
  local sections, cur = {}, { header = nil, body = {} }
  local function flush() if cur.header or #cur.body > 0 then sections[#sections+1] = cur end; cur = { header = nil, body = {} } end
  for _, b in ipairs(blocks) do
    if b.t == "Header" and b.level == 1 then flush(); cur.header = b else cur.body[#cur.body+1] = b end
  end
  flush()
  -- Quarto marks each book file with html-comment markers (<!-- quarto-file-metadata: ... -->)
  -- that its later filters read to number chapters; they must survive when a chapter is dropped.
  local function is_marker(x)
    if x.t == "RawBlock" then return true end
    -- Quarto's own custom nodes (e.g. a conditional block whose condition is false) leave empty divs
    if x.t == "Div" and x.attributes["__quarto_custom"] and pandoc.utils.stringify(x) == "" then return true end
    if (x.t == "Para" or x.t == "Plain") and #x.content > 0 then
      for _, i in ipairs(x.content) do if i.t ~= "RawInline" then return false end end
      return true
    end
    return false
  end
  local function trivial(x)
    if is_marker(x) then return true end
    if x.t == "CodeBlock" and x.classes:includes("quarto-title-block") then return true end
    if x.t == "Para" or x.t == "Plain" then return pandoc.utils.stringify(x) == "" end
    return false
  end
  local out = {}
  for _, sec in ipairs(sections) do
    local before = lifted_count
    local newbody = {}
    for _, b in ipairs(sec.body) do
      local nb = pandoc.Blocks({ b }):walk({ Div = lift })
      for _, x in ipairs(nb) do newbody[#newbody+1] = x end
    end
    local substantive = 0
    for _, x in ipairs(newbody) do
      if not trivial(x) then substantive = substantive + 1 end
    end
    local empty_header = sec.header and #sec.header.content == 0
    if sec.header and substantive == 0 and (lifted_count > before or empty_header) then
      -- host chapter (or the abstract-only index chapter): dropped from body and ToC
      for _, x in ipairs(newbody) do if is_marker(x) then out[#out+1] = x end end
    else
      if sec.header then out[#out+1] = sec.header end
      for _, x in ipairs(newbody) do out[#out+1] = x end
    end
  end
  doc.blocks = pandoc.Blocks(out)

  local front = {}
  for id, bl in pairs(lifted) do front[id] = pandoc.MetaBlocks(bl) end
  if next(front) then doc.meta["thesis-front"] = pandoc.MetaMap(front) end

  -- bibliography: heading text and contents entry come from the profile (C17, 3.11)
  local function untex(v) return (v:gsub("\\([%%#&$_{}])", "%1")) end
  local bibhead = cfg["bibliography.heading"] and untex(cfg["bibliography.heading"])
  local toc_bib = cfg["toc.bibliography"] ~= "false"
  doc.blocks = doc.blocks:walk({
    Header = function(h)
      if h.level == 1 and h.identifier == "references" then
        if bibhead and bibhead ~= "" and pandoc.utils.stringify(h.content) ~= bibhead then
          h.content = pandoc.Inlines({ pandoc.Str(bibhead) })
        end
        if toc_bib then h.classes = h.classes:filter(function(c) return c ~= "unlisted" end)
        elseif not h.classes:includes("unlisted") then h.classes:insert("unlisted") end
        return h
      end
    end,
  })

  doc.meta.indent = true
  return doc
end
