---@module "aalto.groups.plugins"
---
--- Plugin integrations for Aalto.
---
--- FIXES:
--- - Lualine theme now respects transparency settings
--- - Unified signature: get(S, bg, bg_float, opts)

local M = {}

-- -----------------------------------------------
-- LUALINE (EXPLICIT INTEGRATION)
-- -----------------------------------------------

---Generate a semantic lualine theme.
---
---FIX: Now respects transparency settings by using resolved bg.
---
---@param S table Semantic palette
---@param opts table User options (must contain transparent, float_transparent flags)
---@return table lualine theme
function M.lualine_theme(S, opts)
	opts = opts or {}

	-- Resolve transparency for lualine (use same logic as main groups)
	local bg = opts.transparent and "NONE" or S.bg
	local bg_alt = opts.transparent and "NONE" or S.bg_light

	local base = {
		bg = bg,
		bg_alt = bg_alt,
		fg = S.fg,
		fg_dim = S.fg_dark,
	}

	local accents = {
		normal = S.definition,
		insert = S.string,
		visual = S.constant,
		replace = S.error,
		command = S.warn,
	}

	-- -----------------------------------------------
	-- STRICT MODE
	-------------------------------------------------

	if opts.strict then
		for k in pairs(accents) do
			accents[k] = base.fg_dim
		end
	end

	-- -----------------------------------------------
	-- MODE BUILDER
	-------------------------------------------------

	local function mode(accent)
		return {
			a = { fg = accent, bg = base.bg },
			b = { fg = base.fg, bg = base.bg },
			c = { fg = base.fg, bg = base.bg },
			x = { fg = base.fg_dim, bg = base.bg },
			y = { fg = base.fg_dim, bg = base.bg },
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
			a = { fg = base.fg_dim, bg = base.bg },
			b = { fg = base.fg_dim, bg = base.bg },
			c = { fg = base.fg_dim, bg = base.bg },
		},
	}
end

-- -----------------------------------------------
-- MAIN ENTRY
-- -----------------------------------------------

---Generate all plugin highlight groups.
---
---@param S table Semantic palette
---@param bg string Resolved background (S.bg or "NONE")
---@param bg_float string Resolved float background (S.bg_light or "NONE")
---@param opts table User options (contains styles, overrides, etc.)
---@return table groups
function M.get(S, bg, bg_float, opts)
	opts = opts or {}
	local groups = {}

	-- -----------------------------------------------
	-- UI SPEC + GENERATOR
	-------------------------------------------------

	local ui = require("aalto.ui").build(S, bg, bg_float)
	local spec = require("aalto.plugins.spec")

	-- -----------------------------------------------
	-- PLUGIN SPECS
	-------------------------------------------------

	local telescope = {
		panel = { "TelescopeNormal" },
		border = { "TelescopeBorder" },
		selection = { "TelescopeSelection" },
		match = { "TelescopeMatching" },
		title = {
			"TelescopePromptTitle",
			"TelescopeResultsTitle",
			"TelescopePreviewTitle",
		},
		muted = { "TelescopeMultiIcon" },
	}

	local fzf = {
		panel = { "FzfLuaNormal", "FzfLuaPreviewNormal" },
		border = { "FzfLuaBorder", "FzfLuaPreviewBorder" },
		selection = { "FzfLuaCursorLine" },
		match = { "FzfLuaSearch" },
		title = { "FzfLuaTitle" },
		muted = {
			"FzfLuaPathColNr",
			"FzfLuaPathLineNr",
		},
	}

	local cmp = {
		base = { "CmpItemAbbr" },
		match = { "CmpItemAbbrMatch", "CmpItemAbbrMatchFuzzy" },
		muted = { "CmpItemMenu" },
		definition = {
			"CmpItemKindFunction",
			"CmpItemKindMethod",
			"CmpItemKindConstructor",
			"CmpItemKindClass",
			"CmpItemKindInterface",
			"CmpItemKindStruct",
			"CmpItemKindModule",
			"CmpItemKindKeyword",
		},
		string = {
			"CmpItemKindField",
			"CmpItemKindProperty",
			"CmpItemKindUnit",
		},
		constant = {
			"CmpItemKindConstant",
			"CmpItemKindEnum",
			"CmpItemKindEnumMember",
			"CmpItemKindValue",
			"CmpItemKindColor",
		},
	}

	local blink = {
		base = { "BlinkCmpItemAbbr" },
		match = { "BlinkCmpItemAbbrMatch", "BlinkCmpItemAbbrMatchFuzzy" },
		muted = { "BlinkCmpItemSourceName", "BlinkCmpKindText" },
		definition = {
			"BlinkCmpKindFunction",
			"BlinkCmpKindMethod",
			"BlinkCmpKindConstructor",
			"BlinkCmpKindClass",
			"BlinkCmpKindInterface",
			"BlinkCmpKindStruct",
			"BlinkCmpKindModule",
			"BlinkCmpKindKeyword",
			"BlinkCmpKindOperator",
		},
		string = {
			"BlinkCmpKindField",
			"BlinkCmpKindProperty",
			"BlinkCmpKindUnit",
			"BlinkCmpKindFile",
			"BlinkCmpKindFolder",
		},
		constant = {
			"BlinkCmpKindConstant",
			"BlinkCmpKindEnum",
			"BlinkCmpKindEnumMember",
			"BlinkCmpKindValue",
			"BlinkCmpKindColor",
			"BlinkCmpKindReference",
			"BlinkCmpKindTypeParameter",
		},
	}

	local gitsigns = {
		string = { "GitSignsAdd", "GitSignsAddNr", "GitSignsAddLn" },
		constant = { "GitSignsChange", "GitSignsChangeNr", "GitSignsChangeLn" },
		error = { "GitSignsDelete", "GitSignsDeleteNr", "GitSignsDeleteLn" },
	}

	local neotree = {
		panel = {
			"NeoTreeNormal",
			"NeoTreeNormalNC",
			"NeoTreeEndOfBuffer",
		},
		border = { "NeoTreeWinSeparator" },
		title = {
			"NeoTreeRootName",
			"NeoTreeTabActive",
		},
		muted = {
			"NeoTreeTabInactive",
			"NeoTreeTabSeparatorInactive",
			"NeoTreeGitIgnored",
			"NeoTreeHiddenByName",
		},
		selection = { "NeoTreeCursorLine" },
		definition = { "NeoTreeDirectoryName", "NeoTreeDirectoryIcon" },
		string = { "NeoTreeGitAdded", "NeoTreeFileName" },
		constant = { "NeoTreeGitModified" },
		error = { "NeoTreeGitDeleted", "NeoTreeGitConflict" },
		comment = { "NeoTreeDimText", "NeoTreeFloatTitle" },
	}

	local whichkey = {
		title = { "WhichKey", "WhichKeyGroup" },
		muted = { "WhichKeyDesc", "WhichKeySeparator" },
		panel = { "WhichKeyFloat", "WhichKeyBorder" },
		selection = { "WhichKeyTitle" },
		definition = { "WhichKeyIcon" },
	}

	-- -----------------------------------------------
	-- APPLY ALL SPECS
	-------------------------------------------------

	spec.apply_all(groups, ui, {
		telescope,
		fzf,
		cmp,
		blink,
		gitsigns,
		neotree,
		whichkey,
	})

	return groups
end

return M
