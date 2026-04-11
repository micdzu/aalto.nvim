---@module "aalto.groups.editor"
---
--- Core editor highlight groups.
---
--- FIXES:
--- - Now accepts bg and bg_float parameters for transparency support
--- - Uses resolved backgrounds instead of S.bg directly
--- - Fixed NormalNC, SignColumn, FoldColumn to respect transparency

local M = {}

---@param S table Semantic palette
---@param bg string Resolved background (S.bg or "NONE")
---@param bg_float string Resolved float background (S.bg_light or "NONE")
---@param opts table User options (opts.styles consumed here)
function M.get(S, bg, bg_float, opts)
	opts = opts or {}
	local groups = {}
	local styles = opts.styles or {}

	-- -----------------------------------------------
	-- HELPERS
	-- -----------------------------------------------

	---Merge a base spec with a user style override.
	---The user style wins on all keys it provides.
	---@param base table
	---@param override table|nil
	---@return table
	local function with_style(base, override)
		return vim.tbl_extend("force", base, override or {})
	end

	-- -----------------------------------------------
	-- CORE
	-- -----------------------------------------------

	-- Use resolved bg (handles transparency)
	groups.Normal = { fg = S.fg, bg = bg }
	groups.NormalNC = { fg = S.fg, bg = bg } -- non-current windows

	-- Comment respects opts.styles.comments (default: italic = true)
	groups.Comment = with_style({ fg = S.comment }, styles.comments or { italic = true })

	-- -----------------------------------------------
	-- STRINGS
	-------------------------------------------------

	groups.String = { fg = S.string }
	groups.Character = { fg = S.string }

	-- -----------------------------------------------
	-- CONSTANTS
	-------------------------------------------------

	groups.Number = { fg = S.constant }
	groups.Float = { fg = S.constant }
	groups.Boolean = { fg = S.constant }
	groups.Constant = { fg = S.constant }

	-- -----------------------------------------------
	-- DEFINITIONS
	-- keywords respects opts.styles.keywords, etc.
	-------------------------------------------------

	groups.Function = with_style({ fg = S.definition }, styles.definitions or {})
	groups.Type = with_style({ fg = S.definition }, styles.types or {})
	groups.Keyword = with_style({ fg = S.fg }, styles.keywords or {})
	groups.Statement = with_style({ fg = S.fg }, styles.keywords or {})
	groups.Typedef = with_style({ fg = S.definition }, styles.types or {})

	-- -----------------------------------------------
	-- NEUTRAL (NON-SEMANTIC)
	-------------------------------------------------

	groups.Identifier = { fg = S.fg }
	groups.Operator = { fg = S.fg }
	groups.Delimiter = { fg = S.fg }
	groups.Special = { fg = S.fg }
	groups.PreProc = { fg = S.fg }
	groups.Include = { fg = S.definition }
	groups.Define = { fg = S.definition }
	groups.Macro = { fg = S.definition }

	-- -----------------------------------------------
	-- CURSOR / LINE
	-------------------------------------------------

	groups.Cursor = { fg = S.bg, bg = S.fg }
	groups.CursorLine = { bg = S.cursorline }
	groups.CursorLineNr = { fg = S.definition }
	groups.CursorColumn = { bg = S.cursorline }
	groups.ColorColumn = { bg = S.cursorline }

	-- -----------------------------------------------
	-- LINE NUMBERS / GUTTER
	-------------------------------------------------

	groups.LineNr = { fg = S.fg_dark }
	groups.LineNrAbove = { fg = S.fg_dark }
	groups.LineNrBelow = { fg = S.fg_dark }
	-- FIX: Use resolved bg for transparency
	groups.SignColumn = { fg = S.fg_dark, bg = bg }
	groups.FoldColumn = { fg = S.fg_dark, bg = bg }
	groups.Folded = { fg = S.comment, bg = bg_float }

	-- -----------------------------------------------
	-- SELECTION / VISUAL
	-------------------------------------------------

	groups.Visual = { bg = S.selection }
	groups.VisualNOS = { bg = S.selection }

	-- -----------------------------------------------
	-- SEARCH
	-------------------------------------------------

	groups.Search = { fg = S.bg, bg = S.constant }
	groups.IncSearch = { fg = S.bg, bg = S.definition }
	groups.CurSearch = { fg = S.bg, bg = S.definition }
	groups.Substitute = { fg = S.bg, bg = S.string }

	-- -----------------------------------------------
	-- WINDOWS / SPLITS
	-------------------------------------------------

	groups.WinSeparator = { fg = S.fg_dark }
	groups.VertSplit = { fg = S.fg_dark } -- legacy alias
	groups.TabLine = { fg = S.fg_dark, bg = bg }
	groups.TabLineSel = { fg = S.fg, bg = bg }
	groups.TabLineFill = { bg = bg }

	-- -----------------------------------------------
	-- STATUS LINE
	-------------------------------------------------

	groups.StatusLine = { fg = S.fg, bg = bg }
	groups.StatusLineNC = { fg = S.fg_dark, bg = bg }

	-- -----------------------------------------------
	-- COMMAND LINE / MESSAGES
	-------------------------------------------------

	groups.ModeMsg = { fg = S.definition }
	groups.MsgArea = { fg = S.fg }
	groups.MoreMsg = { fg = S.string }
	groups.Question = { fg = S.definition }
	groups.WarningMsg = { fg = S.warn }
	groups.ErrorMsg = { fg = S.error }

	-- -----------------------------------------------
	-- FLOATING WINDOWS / POPUPS
	-- -----------------------------------------------

	-- FIX: Use resolved bg_float for transparency support
	groups.NormalFloat = { fg = S.fg, bg = bg_float }
	groups.FloatBorder = { fg = S.fg_dark, bg = bg_float }
	groups.FloatTitle = { fg = S.definition, bg = bg_float }
	groups.FloatFooter = { fg = S.comment, bg = bg_float }

	-- -----------------------------------------------
	-- COMPLETION MENU (built-in, not nvim-cmp)
	-------------------------------------------------

	groups.Pmenu = { fg = S.fg, bg = bg_float }
	groups.PmenuSel = { fg = S.fg, bg = S.selection }
	groups.PmenuThumb = { bg = S.fg_dark }
	groups.PmenuSbar = { bg = bg_float }

	-- -----------------------------------------------
	-- SPELL
	-------------------------------------------------

	groups.SpellBad = { undercurl = true, sp = S.error }
	groups.SpellCap = { undercurl = true, sp = S.warn }
	groups.SpellRare = { undercurl = true, sp = S.info }
	groups.SpellLocal = { undercurl = true, sp = S.hint }

	-- -----------------------------------------------
	-- DIFF
	-------------------------------------------------

	groups.DiffAdd = { fg = S.string, bg = bg_float }
	groups.DiffChange = { fg = S.definition, bg = bg_float }
	groups.DiffDelete = { fg = S.error, bg = bg_float }
	groups.DiffText = { fg = S.constant, bg = S.selection }

	-- Neovim built-in diff highlights (used by :diffthis and vim.diff)
	groups.Added = { fg = S.string }
	groups.Changed = { fg = S.definition }
	groups.Removed = { fg = S.error }

	-- -----------------------------------------------
	-- DIAGNOSTICS — base severity groups
	-------------------------------------------------

	groups.DiagnosticError = { fg = S.error }
	groups.DiagnosticWarn = { fg = S.warn }
	groups.DiagnosticInfo = { fg = S.info }
	groups.DiagnosticHint = { fg = S.hint }
	groups.DiagnosticOk = { fg = S.string } -- green = success semantically

	-- Tags introduced in Neovim 0.9
	groups.DiagnosticUnnecessary = { fg = S.comment }
	groups.DiagnosticDeprecated = { fg = S.comment, strikethrough = true }

	-- -----------------------------------------------
	-- DIAGNOSTICS — virtual text
	-------------------------------------------------

	groups.DiagnosticVirtualTextError = { fg = S.error, bg = bg_float }
	groups.DiagnosticVirtualTextWarn = { fg = S.warn, bg = bg_float }
	groups.DiagnosticVirtualTextInfo = { fg = S.info, bg = bg_float }
	groups.DiagnosticVirtualTextHint = { fg = S.hint, bg = bg_float }
	groups.DiagnosticVirtualTextOk = { fg = S.string, bg = bg_float }

	-- -----------------------------------------------
	-- DIAGNOSTICS — underlines (sp = underline color)
	-------------------------------------------------

	groups.DiagnosticUnderlineError = { undercurl = true, sp = S.error }
	groups.DiagnosticUnderlineWarn = { undercurl = true, sp = S.warn }
	groups.DiagnosticUnderlineInfo = { undercurl = true, sp = S.info }
	groups.DiagnosticUnderlineHint = { undercurl = true, sp = S.hint }
	groups.DiagnosticUnderlineOk = { undercurl = true, sp = S.string }

	-- -----------------------------------------------
	-- DIAGNOSTICS — floating window text
	-------------------------------------------------

	groups.DiagnosticFloatingError = { fg = S.error }
	groups.DiagnosticFloatingWarn = { fg = S.warn }
	groups.DiagnosticFloatingInfo = { fg = S.info }
	groups.DiagnosticFloatingHint = { fg = S.hint }

	-- -----------------------------------------------
	-- DIAGNOSTICS — sign column
	-------------------------------------------------

	groups.DiagnosticSignError = { fg = S.error, bg = bg }
	groups.DiagnosticSignWarn = { fg = S.warn, bg = bg }
	groups.DiagnosticSignInfo = { fg = S.info, bg = bg }
	groups.DiagnosticSignHint = { fg = S.hint, bg = bg }

	-- -----------------------------------------------
	-- MISC
	-------------------------------------------------

	groups.NonText = { fg = S.fg_dark }
	groups.Whitespace = { fg = S.fg_dark }
	groups.SpecialKey = { fg = S.fg_dark }
	groups.Conceal = { fg = S.fg_dark }
	groups.Directory = { fg = S.definition }
	groups.Title = { fg = S.definition }
	groups.MatchParen = { fg = S.constant, bold = true }
	groups.EndOfBuffer = { fg = S.fg_dark }

	return groups
end

return M
