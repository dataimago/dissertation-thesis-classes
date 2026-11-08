-- thesis-profile.lua -- reads a profile YAML (a strict subset) and writes the .cfg
-- Part of the dataimago-thesis class bundle (house class, step 2).
-- Copyright 2026 dataimago. Distributed under the LaTeX Project Public License
-- 1.3c or later (https://www.latex-project.org/lppl/). Maintainer: dataimago.
-- Version: 2026/11/08 v0.1.0
--
-- Usage (any Lua 5.3+: texlua, `quarto pandoc lua`, lua):
--   texlua thesis-profile.lua <profiles-dir> <id> [outfile]   writes <id>.cfg
--   texlua thesis-profile.lua --json <file.yaml>              prints the parse as JSON
-- Also usable as a module: local P = dofile("thesis-profile.lua")

local M = {}
local MAP = {} -- metatable tag: an (empty) flow map, so {} and [] stay distinct

---------------------------------------------------------------- YAML subset
local function perr(msg, ln) error(("profile YAML: %s (line %s)"):format(msg, tostring(ln or "?")), 0) end

local function strip_comment(s)
  local out, q, i = {}, nil, 1
  while i <= #s do
    local c = s:sub(i, i)
    if q then
      if c == "\\" and q == '"' then out[#out+1] = s:sub(i, i+1); i = i + 1
      elseif c == q then q = nil; out[#out+1] = c
      else out[#out+1] = c end
    elseif c == '"' or c == "'" then
      -- a quote only opens a string at a token start
      local prev = s:sub(i-1, i-1)
      if prev == "" or prev:match("[%s,:%[{]") then q = c end
      out[#out+1] = c
    elseif c == "#" and (i == 1 or s:sub(i-1, i-1):match("%s")) then break
    else out[#out+1] = c end
    i = i + 1
  end
  return (table.concat(out):gsub("%s+$", ""))
end

local function scalar(tok)
  if tok == "true" then return true elseif tok == "false" then return false end
  if tok == "null" or tok == "~" or tok == "" then return nil end
  if tok:match("^-?%d+$") then return math.tointeger(tonumber(tok)) end
  if tok:match("^-?%d*%.%d+$") then return tonumber(tok) end
  return tok
end

local function dq(s, pos, ln)
  local out, i = {}, pos + 1
  while true do
    local c = s:sub(i, i)
    if c == "" then perr("unterminated string", ln) end
    if c == '"' then return table.concat(out), i + 1 end
    if c == "\\" then
      local n = s:sub(i+1, i+1)
      local map = { n = "\n", t = "\t", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
      if n == "u" then out[#out+1] = utf8.char(tonumber(s:sub(i+2, i+5), 16)); i = i + 6
      elseif map[n] then out[#out+1] = map[n]; i = i + 2
      else perr("unsupported escape \\" .. n, ln) end
    else out[#out+1] = c; i = i + 1 end
  end
end

local function sq(s, pos, ln)
  local out, i = {}, pos + 1
  while true do
    local c = s:sub(i, i)
    if c == "" then perr("unterminated string", ln) end
    if c == "'" then
      if s:sub(i+1, i+1) == "'" then out[#out+1] = "'"; i = i + 2
      else return table.concat(out), i + 1 end
    else out[#out+1] = c; i = i + 1 end
  end
end

local parse_flow
local function skip_ws(s, i) return s:find("%S", i) or #s + 1 end

local function flow_value(s, i, ln)
  i = skip_ws(s, i)
  local c = s:sub(i, i)
  if c == "{" or c == "[" then return parse_flow(s, i, ln) end
  if c == '"' then return dq(s, i, ln) end
  if c == "'" then return sq(s, i, ln) end
  local j = i
  while j <= #s do
    local d = s:sub(j, j)
    if d == "," or d == "}" or d == "]" then break end
    if d == ":" and s:sub(j+1, j+1):match("[%s]") then break end
    j = j + 1
  end
  return scalar((s:sub(i, j - 1):gsub("%s+$", ""))), j
end

parse_flow = function(s, i, ln)
  local open = s:sub(i, i)
  local close = open == "{" and "}" or "]"
  local t, n = {}, 0
  if open == "{" then setmetatable(t, MAP) end
  i = skip_ws(s, i + 1)
  if s:sub(i, i) == close then return t, i + 1 end
  while true do
    if open == "{" then
      local k, ni = flow_value(s, i, ln)
      i = skip_ws(s, ni)
      if s:sub(i, i) ~= ":" then perr("expected ':' in flow map", ln) end
      local v; v, i = flow_value(s, i + 1, ln)
      t[tostring(k)] = v
    else
      local v; v, i = flow_value(s, i, ln)
      n = n + 1; t[n] = v
    end
    i = skip_ws(s, i)
    local c = s:sub(i, i)
    if c == "," then i = skip_ws(s, i + 1)
      if s:sub(i, i) == close then return t, i + 1 end
    elseif c == close then return t, i + 1
    else perr("expected ',' or '" .. close .. "'", ln) end
  end
end

local function inline_value(s, ln)
  s = s:gsub("^%s+", "")
  local c = s:sub(1, 1)
  if c == "{" or c == "[" then
    local v, i = parse_flow(s, 1, ln)
    if skip_ws(s, i) <= #s then perr("trailing text after flow collection", ln) end
    return v
  elseif c == '"' then
    local v, i = dq(s, 1, ln)
    if skip_ws(s, i) <= #s then perr("trailing text after string", ln) end
    return v
  elseif c == "'" then
    local v, i = sq(s, 1, ln)
    if skip_ws(s, i) <= #s then perr("trailing text after string", ln) end
    return v
  end
  return scalar(s)
end

function M.parse_yaml(text)
  local lines = {}
  local ln = 0
  for raw in (text .. "\n"):gmatch("(.-)\r?\n") do
    ln = ln + 1
    if raw:find("\t") and raw:match("^%s*\t") then perr("tab indentation", ln) end
    local s = strip_comment(raw)
    if s:match("%S") and not s:match("^%-%-%-%s*$") then
      lines[#lines+1] = { indent = #s:match("^ *"), text = s:gsub("^ +", ""), ln = ln }
    end
  end
  local pos = 1
  local function block(indent)
    local first = lines[pos]
    if not first or first.indent < indent then return nil end
    indent = first.indent
    if first.text:sub(1, 2) == "- " or first.text == "-" then
      local list = {}
      while lines[pos] and lines[pos].indent == indent and lines[pos].text:sub(1, 1) == "-" do
        local rest = lines[pos].text:sub(2):gsub("^%s+", "")
        list[#list+1] = inline_value(rest, lines[pos].ln)
        pos = pos + 1
      end
      return list
    end
    local map = {}
    while lines[pos] and lines[pos].indent == indent do
      local l = lines[pos]
      local k, rest = l.text:match("^([%w_%.%-]+):%s*(.*)$")
      if not k then perr("expected 'key: value'", l.ln) end
      pos = pos + 1
      if rest == "" then
        local nxt = lines[pos]
        if nxt and nxt.indent > indent then map[k] = block(nxt.indent) else map[k] = nil end
      else
        map[k] = inline_value(rest, l.ln)
      end
    end
    if lines[pos] and lines[pos].indent > indent then perr("unexpected indentation", lines[pos].ln) end
    return map
  end
  local r = block(0) or {}
  if lines[pos] then perr("unparsed content", lines[pos].ln) end
  return r
end

---------------------------------------------------------------- JSON (for parity tests)
local function is_list(t) return getmetatable(t) ~= MAP and (#t > 0 or next(t) == nil) end
function M.to_json(v)
  local ty = type(v)
  if ty == "table" then
    local out = {}
    if is_list(v) then
      for i, x in ipairs(v) do out[i] = M.to_json(x) end
      return "[" .. table.concat(out, ",") .. "]"
    end
    local keys = {}
    for k in pairs(v) do keys[#keys+1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do out[#out+1] = M.to_json(k) .. ":" .. M.to_json(v[k]) end
    return "{" .. table.concat(out, ",") .. "}"
  elseif ty == "string" then
    return '"' .. v:gsub('[%c"\\]', function(c)
      local m = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\t"] = "\\t" }
      return m[c] or ("\\u%04x"):format(c:byte())
    end) .. '"'
  elseif ty == "number" then
    if math.type(v) == "integer" then return tostring(v) end
    return ("%.10g"):format(v)
  end
  return tostring(v)
end

---------------------------------------------------------------- merge / flatten
local function is_map(t) return type(t) == "table" and not (#t > 0) and next(t) ~= nil end

function M.merge(base, over)
  local r = {}
  for k, v in pairs(base) do r[k] = v end
  for k, v in pairs(over) do
    if is_map(v) and is_map(r[k]) then r[k] = M.merge(r[k], v) else r[k] = v end
  end
  return r
end

local function flatten(t, prefix, out)
  for k, v in pairs(t) do
    local p = prefix == "" and k or (prefix .. "." .. k)
    if type(v) == "table" and not (#v > 0) and next(v) ~= nil then flatten(v, p, out)
    else out[p] = v end
  end
  return out
end
M.flatten = flatten

-- paths whose value is a template with {slots} and \n line breaks
M.templates = {
  ["frontmatter.titlePage.statement"] = true, ["frontmatter.titlePage.byline"] = true,
  ["frontmatter.copyright.template"] = true, ["frontmatter.approval.statement"] = true,
  ["frontmatter.committee.format"] = true, ["frontmatter.abstract.header"] = true,
}
-- text values (headings, labels): escaped, no slots
M.texts = {
  ["frontmatter.committee.heading"] = true, ["frontmatter.dedication.heading"] = true,
  ["frontmatter.acknowledgments.heading"] = true, ["appendices.label"] = true,
  ["floats.labelSeparator"] = true, ["bibliography.heading"] = true, ["institution.name"] = true,
  ["institution.graduateSchool"] = true,
}
local SKIP = { schemaVersion = true, extends = true, guide = true, sources = true, unstated = true }
local SLOTS = { "title", "author", "authorInverted", "degreeName", "degreeAbbr", "field", "documentType",
  "department", "institution", "graduateSchool", "year", "date", "advisorName", "advisorTitle", "irb",
  "name", "role", "affiliation" }

local function tex_escape(s)
  local map = { ["\\"] = "\\textbackslash{}", ["%"] = "\\%", ["#"] = "\\#", ["&"] = "\\&", ["$"] = "\\$",
    ["_"] = "\\_", ["{"] = "\\{", ["}"] = "\\}", ["~"] = "\\textasciitilde{}", ["^"] = "\\textasciicircum{}" }
  return (s:gsub("[\\%%#&$_{}~^]", map))
end

local function tex_template(s)
  -- protect slots, escape the rest, then restore
  local slots = {}
  local protected = s:gsub("{(%a+)}", function(name)
    for _, n in ipairs(SLOTS) do
      if n == name then slots[#slots+1] = name; return "\1" .. #slots .. "\2" end
    end
  end)
  protected = tex_escape(protected):gsub("\n", "\\\\ ")
  return (protected:gsub("\1(%d+)\2", function(i) return "\\thesisslot{" .. slots[tonumber(i)] .. "}" end))
end

local function cfg_value(path, v)
  if type(v) == "boolean" then return tostring(v) end
  if type(v) == "number" then return M.to_json(v) end
  if type(v) == "table" then
    local parts = {}
    for i, x in ipairs(v) do parts[i] = tostring(x) end
    return table.concat(parts, ",")
  end
  if M.templates[path] then return tex_template(v) end
  if M.texts[path] then return tex_escape(v) end
  if path == "submission.linkColor" then return (v:gsub("^#", "")) end
  if v:find("[\\%%#&$_{}~^\n]") then
    error("profile value at " .. path .. " contains a TeX special character; not allowed outside templates", 0)
  end
  return v
end

local function read_file(p)
  local f = assert(io.open(p, "rb"), "cannot open " .. p)
  local s = f:read("a"); f:close(); return s
end

function M.resolve(dir, id)
  local house = M.parse_yaml(read_file(dir .. "/house.yaml"))
  if id == "house" then return house, house end
  local prof = M.parse_yaml(read_file(dir .. "/" .. id .. ".yaml"))
  if prof.extends ~= "house" then error("profile " .. id .. " must have 'extends: house'", 0) end
  return M.merge(house, prof), prof
end

function M.cfg_text(dir, id)
  local merged = M.resolve(dir, id)
  local flat = {}
  for k, v in pairs(merged) do if not SKIP[k] then flat[k] = v end end
  flat = flatten(flat, "", {})
  local keys = {}
  for k in pairs(flat) do keys[#keys+1] = k end
  table.sort(keys)
  local out = {
    "%% " .. id .. ".cfg -- GENERATED from profiles/" .. id .. ".yaml (with the house defaults merged in).",
    "%% Do not edit: regenerate with  texlua classes/dataimago-thesis/thesis-profile.lua profiles " .. id,
    "%% The profile data is MIT-licensed (repository LICENSE); this file is its compiled form.",
    "\\ProvidesFile{" .. id .. ".cfg}[2026/11/08 compiled profile " .. id .. "]",
  }
  for _, k in ipairs(keys) do
    out[#out+1] = ("\\ThesisCfg{%s}{%s}"):format(k, cfg_value(k, flat[k]))
  end
  return table.concat(out, "\n") .. "\n"
end

-- CLI
if arg and arg[0] and arg[0]:match("thesis%-profile%.lua$") then
  if arg[1] == "--json" then
    print(M.to_json(M.parse_yaml(read_file(arg[2]))))
  elseif arg[1] and arg[2] then
    local text = M.cfg_text(arg[1], arg[2])
    local f = assert(io.open(arg[3] or (arg[1] .. "/" .. arg[2] .. ".cfg"), "wb"))
    f:write(text); f:close()
  end
end

return M
