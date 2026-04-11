---@module "aalto.groups.treesitter"
---
--- TreeSitter highlight capture mappings.
---
--- DESIGN:
--- - Semantic roles → palette (definition, string, constant, comment)
--- - Keywords are neutral (S.fg) + optional styling
--- - Everything is explicitly defined → no fallback to default highlights
---
--- FIXES:
--- - Removed broken syntax
--- - Added local styles + with_style helper
--- - Ensured all keyword groups are properly overridden

local M = {}

---@param S table Semantic palette
---@param bg string Resolved background (unused, API consistency)
---@param bg_float string Resolved float background (unused)
---@param opts table User options
function M.get(S, bg, bg_float, opts)
	opts = opts or {}

	-------------------------------------------------
	-- VALIDATION
	-------------------------------------------------

	if not S or not S.fg or not S.definition or not S.string or not S.constant or not S.comment then
		vim.notify("[aalto] treesitter: incomplete semantic palette", vim.log.levels.ERROR)
		return {}
	end

	-------------------------------------------------
	-- STYLES
	-------------------------------------------------

	local styles = opts.styles or {}

	---Merge base highlight with optional style overrides
	---@param base table
	---@param override table|nil
	---@return table
	local function with_style(base, override)
		return vim.tbl_extend("force", base, override or {})
	end

	-------------------------------------------------
	-- KEYWORDS (neutral by design)
	-------------------------------------------------

	local keyword = with_style({ fg = S.fg }, styles.keywords)

	-------------------------------------------------
	-- GROUPS
	-------------------------------------------------

	return {
		-- -----------------------------------------------
		-- COMMENTS
		-------------------------------------------------

		["@comment"] = { fg = S.comment, italic = true },
		["@comment.documentation"] = { fg = S.comment, italic = true },
		["@comment.error"] = { fg = S.error },
		["@comment.warning"] = { fg = S.warn },
		["@comment.note"] = { fg = S.info },
		["@comment.todo"] = { fg = S.constant },

		-- -----------------------------------------------
		-- STRINGS
		-------------------------------------------------

		["@string"] = { fg = S.string },
		["@string.documentation"] = { fg = S.comment },
		["@string.escape"] = { fg = S.constant },
		["@string.special"] = { fg = S.constant },
		["@string.special.url"] = { fg = S.definition },
		["@string.regexp"] = { fg = S.constant },

		-- -----------------------------------------------
		-- CONSTANTS
		-------------------------------------------------

		["@number"] = { fg = S.constant },
		["@number.float"] = { fg = S.constant },
		["@boolean"] = { fg = S.constant },
		["@constant"] = { fg = S.constant },
		["@constant.builtin"] = { fg = S.constant },
		["@constant.macro"] = { fg = S.constant },

		-- -----------------------------------------------
		-- DEFINITIONS — functions
		-------------------------------------------------

		["@function"] = { fg = S.definition },
		["@function.call"] = { fg = S.definition },
		["@function.builtin"] = { fg = S.definition },
		["@function.macro"] = { fg = S.definition },
		["@function.method"] = { fg = S.definition },
		["@function.method.call"] = { fg = S.definition },
		["@method"] = { fg = S.definition },
		["@method.call"] = { fg = S.definition },
		["@constructor"] = { fg = S.definition },

		-- -----------------------------------------------
		-- DEFINITIONS — types
		-------------------------------------------------

		["@type"] = { fg = S.definition },
		["@type.builtin"] = { fg = S.definition },
		["@type.definition"] = { fg = S.definition },
		["@type.qualifier"] = { fg = S.definition },

		-- -----------------------------------------------
		-- KEYWORDS (critical: fully overridden)
		-------------------------------------------------

		["@keyword"] = keyword,
		["@keyword.function"] = keyword,
		["@keyword.return"] = keyword,
		["@keyword.operator"] = keyword,
		["@keyword.import"] = keyword,
		["@keyword.type"] = keyword,
		["@keyword.modifier"] = keyword,
		["@keyword.repeat"] = keyword,
		["@keyword.conditional"] = keyword,
		["@keyword.exception"] = keyword,
		["@keyword.debug"] = keyword,
		["@keyword.directive"] = keyword,
		["@keyword.directive.define"] = keyword,

		-- -----------------------------------------------
		-- MODULES / NAMESPACES
		-------------------------------------------------

		["@module"] = { fg = S.definition },
		["@namespace"] = { fg = S.definition },
		["@label"] = { fg = S.definition },

		-- -----------------------------------------------
		-- NEUTRAL (non-semantic)
		-------------------------------------------------

		["@variable"] = { fg = S.fg },
		["@variable.parameter"] = { fg = S.fg },
		["@variable.member"] = { fg = S.fg },
		["@variable.builtin"] = { fg = S.fg },

		["@property"] = { fg = S.fg },
		["@field"] = { fg = S.fg },
		["@attribute"] = { fg = S.fg },

		["@operator"] = { fg = S.fg },
		["@punctuation"] = { fg = S.fg },
		["@punctuation.bracket"] = { fg = S.fg },
		["@punctuation.delimiter"] = { fg = S.fg },
		["@punctuation.special"] = { fg = S.fg },

		["@tag"] = { fg = S.definition },
		["@tag.attribute"] = { fg = S.fg },
		["@tag.delimiter"] = { fg = S.fg },

		-- -----------------------------------------------
		-- MARKDOWN
		-------------------------------------------------

		["@markup.heading"] = { fg = S.definition, bold = true },
		["@markup.heading.1"] = { fg = S.definition, bold = true },
		["@markup.heading.2"] = { fg = S.definition, bold = true },
		["@markup.heading.3"] = { fg = S.definition },
		["@markup.heading.4"] = { fg = S.definition },
		["@markup.heading.5"] = { fg = S.definition },
		["@markup.heading.6"] = { fg = S.definition },

		["@markup.link"] = { fg = S.definition },
		["@markup.link.url"] = { fg = S.definition },
		["@markup.link.label"] = { fg = S.definition },

		["@markup.raw"] = { fg = S.constant },
		["@markup.raw.block"] = { fg = S.constant },

		["@markup.italic"] = { italic = true },
		["@markup.strong"] = { bold = true },
		["@markup.strikethrough"] = { strikethrough = true },
		["@markup.underline"] = { underline = true },

		["@markup.quote"] = { fg = S.comment, italic = true },
		["@markup.list"] = { fg = S.fg },
		["@markup.list.checked"] = { fg = S.string },
		["@markup.list.unchecked"] = { fg = S.fg_dark },

		["@markup.math"] = { fg = S.constant },

		-- -----------------------------------------------
		-- DIFF
		-------------------------------------------------

		["@diff.plus"] = { fg = S.string },
		["@diff.minus"] = { fg = S.error },
		["@diff.delta"] = { fg = S.constant },
	}
end

return M
