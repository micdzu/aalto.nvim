---@module "aalto.groups.plugins"
---
--- Third‑party plugin highlight groups. This is where we make other people's
--- software look like it was designed for Aalto. Contributions welcome.

local M = {}

--- Generate plugin highlight groups.
---@param S table      Semantic palette
---@param bg string    Resolved background (or "NONE")
---@param bg_float string Resolved float background
---@param opts table   User options (may contain lualine_style)
---@return table groups
function M.get(S, bg, bg_float, opts)
	opts = opts or {}
	local link = require("aalto.groups.link").create(S)

	local groups = {
		-- Telescope
		TelescopeNormal = { fg = S.fg, bg = bg_float },
		TelescopeBorder = { fg = S.fg_dark, bg = bg_float },
		TelescopeTitle = link("definition"),
		TelescopeSelection = { bg = S.selection },
		TelescopeSelectionCaret = link("definition"),
		TelescopeMatching = link("definition"),
		TelescopePromptPrefix = link("definition"),
		TelescopeResultsDiffAdd = link("string"),
		TelescopeResultsDiffChange = link("constant"),
		TelescopeResultsDiffDelete = link("error"),

		-- fzf-lua
		FzfLuaNormal = { fg = S.fg, bg = bg_float },
		FzfLuaBorder = { fg = S.fg_dark, bg = bg_float },
		FzfLuaTitle = link("definition"),
		FzfLuaCursorLine = { bg = S.selection },
		FzfLuaSearch = link("definition"),

		-- nvim-cmp
		CmpItemAbbr = { fg = S.fg },
		CmpItemAbbrMatch = link("definition"),
		CmpItemAbbrMatchFuzzy = link("definition"),
		CmpItemKind = link("constant"),
		CmpItemMenu = { fg = S.fg_dark },
		CmpItemKindFunction = link("definition"),
		CmpItemKindMethod = link("definition"),
		CmpItemKindConstructor = link("definition"),
		CmpItemKindClass = link("definition"),
		CmpItemKindInterface = link("definition"),
		CmpItemKindStruct = link("definition"),
		CmpItemKindModule = link("definition"),
		CmpItemKindKeyword = link("definition"),
		CmpItemKindField = link("string"),
		CmpItemKindProperty = link("string"),
		CmpItemKindUnit = link("string"),
		CmpItemKindConstant = link("constant"),
		CmpItemKindEnum = link("constant"),
		CmpItemKindEnumMember = link("constant"),
		CmpItemKindValue = link("constant"),
		CmpItemKindColor = link("constant"),
		CmpItemKindReference = link("constant"),
		CmpItemKindTypeParameter = link("definition"),
		CmpItemKindOperator = { fg = S.fg },
		CmpItemKindFile = { fg = S.fg },
		CmpItemKindFolder = link("definition"),

		-- blink.cmp
		BlinkCmpItemAbbr = { fg = S.fg },
		BlinkCmpItemAbbrMatch = link("definition"),
		BlinkCmpItemAbbrMatchFuzzy = link("definition"),
		BlinkCmpKindText = { fg = S.fg_dark },
		BlinkCmpKindFunction = link("definition"),
		BlinkCmpKindMethod = link("definition"),
		BlinkCmpKindConstructor = link("definition"),
		BlinkCmpKindClass = link("definition"),
		BlinkCmpKindInterface = link("definition"),
		BlinkCmpKindStruct = link("definition"),
		BlinkCmpKindModule = link("definition"),
		BlinkCmpKindKeyword = link("definition"),
		BlinkCmpKindField = link("string"),
		BlinkCmpKindProperty = link("string"),
		BlinkCmpKindUnit = link("string"),
		BlinkCmpKindConstant = link("constant"),
		BlinkCmpKindEnum = link("constant"),
		BlinkCmpKindEnumMember = link("constant"),
		BlinkCmpKindValue = link("constant"),
		BlinkCmpKindColor = link("constant"),
		BlinkCmpKindReference = link("constant"),
		BlinkCmpKindTypeParameter = link("definition"),
		BlinkCmpKindOperator = { fg = S.fg },
		BlinkCmpKindFile = { fg = S.fg },
		BlinkCmpKindFolder = link("definition"),
		BlinkCmpItemSourceName = { fg = S.fg_dark },

		-- GitSigns
		GitSignsAdd = link("string"),
		GitSignsChange = link("constant"),
		GitSignsDelete = link("error"),
		GitSignsAddNr = link("string"),
		GitSignsChangeNr = link("constant"),
		GitSignsDeleteNr = link("error"),
		GitSignsAddLn = link("string"),
		GitSignsChangeLn = link("constant"),
		GitSignsDeleteLn = link("error"),
		GitSignsCurrentLineBlame = { fg = S.fg_dark },

		-- Neo-tree
		NeoTreeNormal = { fg = S.fg, bg = bg },
		NeoTreeNormalNC = { fg = S.fg, bg = bg },
		NeoTreeEndOfBuffer = { fg = bg },
		NeoTreeWinSeparator = { fg = S.fg_dark },
		NeoTreeRootName = link("definition"),
		NeoTreeTabActive = link("definition"),
		NeoTreeTabInactive = { fg = S.fg_dark },
		NeoTreeTabSeparatorInactive = { fg = S.fg_dark },
		NeoTreeGitIgnored = { fg = S.fg_dark },
		NeoTreeHiddenByName = { fg = S.fg_dark },
		NeoTreeCursorLine = { bg = S.cursorline },
		NeoTreeDirectoryName = link("definition"),
		NeoTreeDirectoryIcon = link("definition"),
		NeoTreeFileName = { fg = S.fg },
		NeoTreeFileIcon = { fg = S.fg },
		NeoTreeGitAdded = link("string"),
		NeoTreeGitModified = link("constant"),
		NeoTreeGitDeleted = link("error"),
		NeoTreeGitConflict = link("error"),
		NeoTreeDimText = { fg = S.fg_dark },
		NeoTreeFloatTitle = link("definition"),

		-- NvimTree (for the folks who prefer it)
		NvimTreeNormal = { fg = S.fg, bg = bg },
		NvimTreeRootFolder = link("definition"),
		NvimTreeFolderName = link("definition"),
		NvimTreeFolderIcon = link("definition"),
		NvimTreeEmptyFolderName = { fg = S.fg_dark },
		NvimTreeOpenedFolderName = link("definition"),
		NvimTreeIndentMarker = { fg = S.fg_dark },
		NvimTreeGitDirty = link("constant"),
		NvimTreeGitStaged = link("string"),
		NvimTreeGitDeleted = link("error"),
		NvimTreeCursorLine = { bg = S.cursorline },

		-- WhichKey
		WhichKey = link("definition"),
		WhichKeyGroup = link("definition"),
		WhichKeyDesc = { fg = S.fg },
		WhichKeySeparator = { fg = S.fg_dark },
		WhichKeyValue = { fg = S.fg_dark },
		WhichKeyIcon = link("definition"),

		-- Trouble
		TroubleNormal = { fg = S.fg, bg = bg_float },
		TroubleBorder = { fg = S.fg_dark, bg = bg_float },
		TroubleTitle = link("definition"),
		TroubleText = { fg = S.fg },
		TroubleCount = link("constant"),
		TroubleIndent = { fg = S.fg_dark },
		TroubleError = link("error"),
		TroubleErrorIcon = link("error"),
		TroubleWarning = link("warn"),
		TroubleWarningIcon = link("warn"),
		TroubleInformation = link("info"),
		TroubleInformationIcon = link("info"),
		TroubleHint = link("hint"),
		TroubleHintIcon = link("hint"),
		TroubleFoldIcon = { fg = S.fg_dark },

		-- nvim-notify
		NotifyBackground = { bg = bg_float },
		NotifyBorder = { fg = S.fg_dark },
		NotifyTitle = link("definition"),
		NotifyERRORBody = link("error"),
		NotifyERRORBorder = link("error"),
		NotifyERRORIcon = link("error"),
		NotifyERRORTitle = link("error"),
		NotifyWARNBody = link("warn"),
		NotifyWARNBorder = link("warn"),
		NotifyWARNIcon = link("warn"),
		NotifyWARNTitle = link("warn"),
		NotifyINFOBody = link("info"),
		NotifyINFOBorder = link("info"),
		NotifyINFOIcon = link("info"),
		NotifyINFOTitle = link("info"),
		NotifyHINTBody = link("hint"),
		NotifyHINTBorder = link("hint"),
		NotifyHINTIcon = link("hint"),
		NotifyHINTTitle = link("hint"),
		NotifyDEBUGBody = { fg = S.fg_dark },
		NotifyTRACEBody = { fg = S.fg_dark },

		-- Flash.nvim
		FlashMatch = link("inv_definition"),
		FlashCurrent = link("inv_constant"),
		FlashLabel = { fg = S.bg, bg = S.definition, bold = true },

		-- Illuminate
		IlluminatedWordText = { bg = S.selection },
		IlluminatedWordRead = { bg = S.selection },
		IlluminatedWordWrite = { bg = S.selection },

		-- Indent Blankline
		IblIndent = { fg = S.fg_dark },
		IblScope = link("definition"),
		IndentBlanklineChar = { fg = S.fg_dark },
		IndentBlanklineContextChar = link("definition"),
		IndentBlanklineContextStart = link("definition"),

		-- Rainbow Delimiters
		RainbowDelimiterRed = link("error"),
		RainbowDelimiterYellow = link("constant"),
		RainbowDelimiterBlue = link("definition"),
		RainbowDelimiterGreen = link("string"),
		RainbowDelimiterCyan = link("info"),
		RainbowDelimiterViolet = link("constant"),

		-- todo-comments
		TodoFgTODO = link("constant"),
		TodoFgFIX = link("error"),
		TodoFgWARN = link("warn"),
		TodoFgINFO = link("info"),
		TodoFgHINT = link("hint"),

		-- Navic
		NavicText = { fg = S.fg },
		NavicSeparator = { fg = S.fg_dark },
		NavicIconsFile = { fg = S.fg },
		NavicIconsMethod = link("definition"),
		NavicIconsClass = link("definition"),

		-- BufferLine
		BufferLineFill = { bg = bg },
		BufferLineBackground = { fg = S.fg_dark, bg = bg },
		BufferLineBufferSelected = { fg = S.fg, bg = bg },
		BufferLineIndicatorSelected = link("definition"),
		BufferLineSeparator = { fg = S.fg_dark },
		BufferLineCloseButton = { fg = S.fg_dark },
		BufferLineCloseButtonSelected = { fg = S.fg },

		-- Statusline custom groups (for built‑in statusline)
		AaltoSLFg = { fg = S.fg, bg = bg },
		AaltoSLDim = { fg = S.fg_dark, bg = bg },
		AaltoSLNormal = { fg = S.definition, bg = bg },
		AaltoSLInsert = { fg = S.string, bg = bg },
		AaltoSLVisual = { fg = S.constant, bg = bg },
		AaltoSLReplace = { fg = S.error, bg = bg },
		AaltoSLCommand = { fg = S.warn, bg = bg },
		AaltoSLError = { fg = S.error, bg = bg },
		AaltoSLWarn = { fg = S.warn, bg = bg },
		AaltoSLStr = { fg = S.string, bg = bg },
		AaltoSLConst = { fg = S.constant, bg = bg },
		AaltoSLComment = { fg = S.comment, bg = bg },
	}

	return groups
end

--- Generate a lualine-compatible theme table.
---@param S table   Semantic palette
---@param opts table User options (transparent, lualine_style)
---@return table theme
function M.lualine_theme(S, opts)
	opts = opts or {}
	local style = opts.lualine_style or "minimal"
	local bg = opts.transparent and "NONE" or S.bg
	local bg_alt = opts.transparent and "NONE" or S.bg_light

	local base = { fg = S.fg, bg = bg, bg_alt = bg_alt }
	local accents = {
		normal = S.definition,
		insert = S.string,
		visual = S.constant,
		replace = S.error,
		command = S.warn,
	}

	if style == "minimal" then
		local function mode(accent)
			return {
				a = { fg = accent, bg = base.bg },
				b = { fg = base.fg, bg = base.bg },
				c = { fg = base.fg, bg = base.bg },
				x = { fg = S.fg_dark, bg = base.bg },
				y = { fg = S.fg_dark, bg = base.bg },
				z = { fg = base.fg, bg = base.bg },
			}
		end
		return {
			normal = mode(accents.normal),
			insert = mode(accents.insert),
			visual = mode(accents.visual),
			replace = mode(accents.replace),
			command = mode(accents.command),
			inactive = {
				a = { fg = S.fg_dark, bg = base.bg },
				b = { fg = S.fg_dark, bg = base.bg },
				c = { fg = S.fg_dark, bg = base.bg },
			},
		}
	else -- "full"
		local function mode_full(accent)
			return {
				a = { fg = S.bg, bg = accent, gui = "bold" },
				b = { fg = base.fg, bg = bg_alt },
				c = { fg = S.fg_dark, bg = bg },
				x = { fg = S.fg_dark, bg = bg },
				y = { fg = base.fg, bg = bg_alt },
				z = { fg = S.bg, bg = accent },
			}
		end
		return {
			normal = mode_full(accents.normal),
			insert = mode_full(accents.insert),
			visual = mode_full(accents.visual),
			replace = mode_full(accents.replace),
			command = mode_full(accents.command),
			inactive = {
				a = { fg = S.fg_dark, bg = bg_alt },
				b = { fg = S.fg_dark, bg = bg },
				c = { fg = S.fg_dark, bg = bg },
			},
		}
	end
end

return M
