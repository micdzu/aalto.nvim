---@module "aalto.groups.editor"
---
--- Core editor highlight groups. This is the bedrock—everything else builds on it.
--- If it's not defined here, it probably falls back to something ugly.

local M = {}

function M.get(S, bg, bg_float, opts)
	opts = opts or {}
	local styles = opts.styles or {}

	local link = require("aalto.groups.link").create(S)

	local groups = {}

	-- -------------------------------------------
	-- Normal text and background
	-- -------------------------------------------
	groups.Normal = { fg = S.fg, bg = bg }
	groups.NormalNC = { fg = S.fg_dark, bg = bg } -- inactive windows

	-- -------------------------------------------
	-- Comments
	-- -------------------------------------------
	groups.Comment = link("comment", styles.comments)

	-- -------------------------------------------
	-- Strings
	-- -------------------------------------------
	groups.String = link("string")
	groups.Character = link("string")

	-- -------------------------------------------
	-- Constants
	-- -------------------------------------------
	groups.Number = link("constant")
	groups.Float = link("constant")
	groups.Boolean = link("constant")
	groups.Constant = link("constant")

	-- -------------------------------------------
	-- Definitions
	-- -------------------------------------------
	groups.Function = link("definition")
	groups.Type = link("definition")
	groups.Typedef = link("definition")

	-- Keywords (neutral foreground, optional italic)
	groups.Keyword = { fg = S.fg, italic = styles.keywords and styles.keywords.italic }
	groups.Statement = { fg = S.fg, italic = styles.keywords and styles.keywords.italic }

	-- Preprocessor
	groups.Include = link("definition")
	groups.Define = link("definition")
	groups.Macro = link("definition")

	-- Identifiers and punctuation
	groups.Identifier = { fg = S.fg }
	groups.Operator = { fg = S.fg }
	groups.Delimiter = { fg = S.fg }
	groups.Special = { fg = S.fg }
	groups.PreProc = { fg = S.fg }

	-- -------------------------------------------
	-- Cursor and line highlights
	-- -------------------------------------------
	groups.Cursor = { fg = S.bg, bg = S.fg }
	groups.CursorIM = { fg = S.bg, bg = S.fg } -- insert mode cursor (same)
	groups.CursorLine = { bg = S.cursorline }
	groups.CursorColumn = { bg = S.cursorline }
	groups.ColorColumn = { bg = S.cursorline }
	groups.CursorLineNr = link("definition")

	-- -------------------------------------------
	-- Line numbers and gutter
	-- -------------------------------------------
	groups.LineNr = { fg = S.fg_dark }
	groups.LineNrAbove = { fg = S.fg_dark }
	groups.LineNrBelow = { fg = S.fg_dark }
	groups.SignColumn = { fg = S.fg_dark, bg = bg }
	groups.FoldColumn = { fg = S.fg_dark, bg = bg }
	groups.Folded = { fg = S.comment, bg = bg_float }

	-- -------------------------------------------
	-- Visual selection
	-- -------------------------------------------
	groups.Visual = { bg = S.selection }
	groups.VisualNOS = { bg = S.selection }

	-- -------------------------------------------
	-- Search
	-- -------------------------------------------
	groups.Search = link("inv_constant")
	groups.IncSearch = link("inv_definition")
	groups.CurSearch = link("inv_definition")
	groups.Substitute = link("inv_string")
	groups.MatchWord = { bg = S.selection } -- word under cursor (e.g., with *)

	-- -------------------------------------------
	-- Window separators and tabs
	-- -------------------------------------------
	groups.WinSeparator = { fg = S.fg_dark }
	groups.VertSplit = { fg = S.fg_dark } -- legacy alias

	groups.TabLine = { fg = S.fg_dark, bg = bg }
	groups.TabLineSel = { fg = S.fg, bg = bg }
	groups.TabLineFill = { bg = bg }

	-- -------------------------------------------
	-- Statusline
	-- -------------------------------------------
	groups.StatusLine = { fg = S.fg, bg = bg }
	groups.StatusLineNC = { fg = S.fg_dark, bg = bg }

	-- -------------------------------------------
	-- Messages and prompts
	-- -------------------------------------------
	groups.ModeMsg = link("definition")
	groups.MsgArea = { fg = S.fg }
	groups.MoreMsg = link("string")
	groups.Question = link("definition")
	groups.WarningMsg = link("warn")
	groups.ErrorMsg = link("error")
	groups.MsgSeparator = { fg = S.fg_dark }

	-- -------------------------------------------
	-- Floating windows and popups
	-- -------------------------------------------
	groups.NormalFloat = { fg = S.fg, bg = bg_float }
	groups.FloatBorder = { fg = S.fg_dark, bg = bg_float }
	groups.FloatTitle = { fg = S.definition, bg = bg_float }
	groups.FloatFooter = { fg = S.fg_dark, bg = bg_float } -- "Press q to close" vibes
	-- -------------------------------------------
	-- Popup menu (completion)
	-- -------------------------------------------
	groups.Pmenu = { fg = S.fg, bg = bg_float }
	groups.PmenuSel = { fg = S.fg, bg = S.selection }
	groups.PmenuThumb = { bg = S.fg_dark }
	groups.PmenuSbar = { bg = bg_float }
	groups.WildMenu = { fg = S.fg, bg = S.selection, bold = true }

	-- -------------------------------------------
	-- Spelling
	-- -------------------------------------------
	groups.SpellBad = { undercurl = true, sp = S.error }
	groups.SpellCap = { undercurl = true, sp = S.warn }
	groups.SpellRare = { undercurl = true, sp = S.info }
	groups.SpellLocal = { undercurl = true, sp = S.hint }

	-- -------------------------------------------
	-- Diff
	-- -------------------------------------------
	groups.DiffAdd = { fg = S.string }
	groups.DiffChange = { fg = S.constant }
	groups.DiffDelete = { fg = S.error }
	groups.DiffText = { fg = S.definition }
	groups.Added = link("string")
	groups.Changed = link("constant")
	groups.Removed = link("error")

	-- -------------------------------------------
	-- Diagnostics
	-- -------------------------------------------
	groups.DiagnosticError = link("error")
	groups.DiagnosticWarn = link("warn")
	groups.DiagnosticInfo = link("info")
	groups.DiagnosticHint = link("hint")
	groups.DiagnosticOk = link("string")

	groups.DiagnosticVirtualTextError = { fg = S.error, bg = bg_float }
	groups.DiagnosticVirtualTextWarn = { fg = S.warn, bg = bg_float }
	groups.DiagnosticVirtualTextInfo = { fg = S.info, bg = bg_float }
	groups.DiagnosticVirtualTextHint = { fg = S.hint, bg = bg_float }

	groups.DiagnosticUnderlineError = { undercurl = true, sp = S.error }
	groups.DiagnosticUnderlineWarn = { undercurl = true, sp = S.warn }
	groups.DiagnosticUnderlineInfo = { undercurl = true, sp = S.info }
	groups.DiagnosticUnderlineHint = { undercurl = true, sp = S.hint }

	groups.DiagnosticSignError = { fg = S.error, bg = bg }
	groups.DiagnosticSignWarn = { fg = S.warn, bg = bg }
	groups.DiagnosticSignInfo = { fg = S.info, bg = bg }
	groups.DiagnosticSignHint = { fg = S.hint, bg = bg }

	-- -------------------------------------------
	-- Miscellaneous
	-- -------------------------------------------
	groups.NonText = { fg = S.fg_dark }
	groups.Whitespace = { fg = S.fg_dark }
	groups.SpecialKey = { fg = S.fg_dark }
	groups.Conceal = { fg = S.fg_dark }
	groups.Directory = link("definition")
	groups.Title = link("definition")
	groups.MatchParen = { bg = S.selection }
	groups.EndOfBuffer = { fg = bg }
	groups.QuickFixLine = { bg = S.selection, bold = true }
	groups.Terminal = { fg = S.fg, bg = bg }

	-- GUI elements (for Neovim GUI clients)
	groups.ToolbarLine = { bg = bg }
	groups.ToolbarButton = { fg = S.fg, bg = bg_float }

	-- Fallbacks for older highlight names
	groups.Error = link("error")
	groups.Todo = link("constant")

	return groups
end

return M
