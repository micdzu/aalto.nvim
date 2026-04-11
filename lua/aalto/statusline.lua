---@module "aalto.statusline"
---
--- Native Aalto statusline.
---
--- Philosophy:
--- - Minimal, text-first UI
--- - Semantic coloring only where meaningful (mode accents)
--- - No visual noise or background blocks
--- - Context-aware: shows only relevant info per buffer
---
--- Usage:
--- vim.o.statusline = "%!v:lua.require('aalto.statusline').build(require('aalto').get_palette())()"
---
--- Or via the setup callback:
--- config = function()
---   local aalto = require("aalto")
---   local S = aalto.setup({ ... })
---   vim.o.statusline = "%!v:lua.require('aalto.statusline').build(" .. vim.inspect(S) .. ")()"
--- end

local M = {}

-- -----------------------------------------------
-- HIGHLIGHTS
-- -----------------------------------------------

---Set up statusline highlight groups.
---@param S table Semantic palette
local function set_hl(S)
  -- Use pcall to avoid errors if palette is incomplete
  local ok = pcall(function()
    vim.api.nvim_set_hl(0, "AaltoSLNormal", { fg = S.fg, bg = S.bg })
    vim.api.nvim_set_hl(0, "AaltoSLDim", { fg = S.fg_dark, bg = S.bg })

    vim.api.nvim_set_hl(0, "AaltoSLDef", { fg = S.definition, bg = S.bg })
    vim.api.nvim_set_hl(0, "AaltoSLStr", { fg = S.string, bg = S.bg })
    vim.api.nvim_set_hl(0, "AaltoSLConst", { fg = S.constant, bg = S.bg })

    vim.api.nvim_set_hl(0, "AaltoSLError", { fg = S.error, bg = S.bg })
    vim.api.nvim_set_hl(0, "AaltoSLWarn", { fg = S.warn, bg = S.bg })

    vim.api.nvim_set_hl(0, "AaltoSLComment", { fg = S.comment, bg = S.bg })
  end)
  
  if not ok then
    vim.notify("[aalto.statusline] Failed to set highlights - incomplete palette", vim.log.levels.WARN)
  end
end

-- -----------------------------------------------
-- HELPERS
-- -----------------------------------------------

---Wrap text in highlight group.
---@param group string Highlight group name
---@param text string Text to highlight
---@return string
local function hl(group, text)
  return "%#" .. group .. "#" .. text .. "%*"
end

---Map the current Vim mode to a semantic highlight group.
---
---Semantic intent:
--- normal → definition (structure: you are navigating the program)
--- insert → string (you are writing text/data)
--- visual → constant (you are selecting a value/range)
--- replace → error (destructive edit)
--- command → warn (executing a command)
---
---@return string Highlight group name
local function mode_group()
  local m = vim.fn.mode()
  if m:match("i") then return "AaltoSLStr" end
  if m:match("[vV]") or m:match("\\22") then return "AaltoSLConst" end  -- \22 is <C-v>
  if m:match("R") then return "AaltoSLError" end
  if m:match("c") then return "AaltoSLWarn" end
  return "AaltoSLDef"
end

---Get current filename with indicators.
---@return string
local function filename()
  local name = vim.fn.expand("%:t")
  return name ~= "" and name or "[No Name]"
end

---Get modification indicator.
---@return string
local function modified()
  return vim.bo.modified and " +" or ""
end

---Get readonly indicator.
---@return string
local function readonly()
  return (vim.bo.readonly or not vim.bo.modifiable) and " 󰌾" or ""
end

-- -----------------------------------------------
-- GIT
-- -----------------------------------------------

---Get git branch name.
---@return string
local function git_branch()
  local g = vim.b.gitsigns_head
  if not g or g == "" then return "" end
  return hl("AaltoSLComment", " " .. g)
end

---Get git diff stats.
---@return string
local function git_diff()
  local g = vim.b.gitsigns_status_dict
  if not g then return "" end

  local parts = {}
  if g.added and g.added > 0 then table.insert(parts, hl("AaltoSLStr", "+" .. g.added)) end
  if g.changed and g.changed > 0 then table.insert(parts, hl("AaltoSLConst", "~" .. g.changed)) end
  if g.removed and g.removed > 0 then table.insert(parts, hl("AaltoSLError", "-" .. g.removed)) end

  return table.concat(parts, " ")
end

-- -----------------------------------------------
-- LSP
-- -----------------------------------------------

---Get active LSP client name.
---@return string
local function lsp()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then return "" end
  return hl("AaltoSLComment", clients[1].name)
end

-- -----------------------------------------------
-- DIAGNOSTICS
-- -----------------------------------------------

---Get diagnostic counts.
---@return string
local function diagnostics()
  local ok, e = pcall(function()
    return #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  end)
  local ok2, w = pcall(function()
    return #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
  end)
  
  if not ok then e = 0 end
  if not ok2 then w = 0 end

  if e == 0 and w == 0 then return "" end

  local parts = {}
  if e > 0 then table.insert(parts, hl("AaltoSLError", "E" .. e)) end
  if w > 0 then table.insert(parts, hl("AaltoSLWarn", "W" .. w)) end

  return table.concat(parts, " ")
end

-- -----------------------------------------------
-- FILE INFO
-- -----------------------------------------------

---Get file encoding, format, and type.
---@return string
local function fileinfo()
  local ft = vim.bo.filetype ~= "" and vim.bo.filetype or "plain"
  local enc = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
  local fmt = vim.bo.fileformat
  return hl("AaltoSLDim", string.format("%s %s %s", enc, fmt, ft))
end

---Get cursor position.
---@return string
local function position()
  return hl("AaltoSLNormal", string.format("%d:%d", vim.fn.line("."), vim.fn.col(".")))
end

-- -----------------------------------------------
-- BUILD
-- -----------------------------------------------

---Build and return the statusline render function.
---
---Initializes highlight groups from the palette on first call.
---Returns a function that Neovim calls on every statusline redraw.
---
---@param S table|nil Semantic palette (from require("aalto").get_palette())
---@return function statusline render function
function M.build(S)
  -- Graceful fallback if palette not available
  if not S then
    return function()
      return " [aalto: no palette] "
    end
  end

  set_hl(S)

  return function()
    local left = {}
    local right = {}

    -- Mode indicator + filename
    table.insert(left, hl(mode_group(), "●"))
    table.insert(left, hl("AaltoSLNormal", filename() .. modified() .. readonly()))

    -- Git branch
    local branch = git_branch()
    if branch ~= "" then table.insert(left, " " .. branch) end

    -- Git diff stats
    local diff = git_diff()
    if diff ~= "" then table.insert(left, " " .. diff) end

    -- Diagnostics
    local diag = diagnostics()
    if diag ~= "" then table.insert(left, " " .. diag) end

    -- Active LSP client
    local lsp_name = lsp()
    if lsp_name ~= "" then table.insert(left, " " .. lsp_name) end

    -- Right side
    table.insert(right, fileinfo())
    table.insert(right, hl("AaltoSLDim", "│"))
    table.insert(right, position())

    return table.concat(left, " ") .. "%=" .. table.concat(right, " ")
  end
end

return M