---@module "aalto.groups.lsp"
---
--- LSP semantic token highlight mappings.
---
--- DESIGN:
--- - Semantic roles map directly to palette (definition, string, etc.)
--- - Keywords are intentionally neutral (S.fg)
--- - Optional styling via opts.styles.keywords
---
--- FIXES:
--- - Added local styles + with_style helper
--- - Removed undefined globals
--- - Ensured deterministic keyword handling

local M = {}

---@param S table Semantic palette
---@param bg string Resolved background (unused, kept for API consistency)
---@param bg_float string Resolved float background (unused)
---@param opts table User options
function M.get(S, bg, bg_float, opts)
	opts = opts or {}

	-------------------------------------------------
	-- VALIDATION
	-------------------------------------------------

	if not S or not S.fg or not S.definition or not S.constant or not S.comment or not S.selection then
		vim.notify("[aalto] lsp: incomplete semantic palette", vim.log.levels.ERROR)
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
	-- KEYWORD STYLE (NEUTRAL BY DESIGN)
	-------------------------------------------------

	local keyword = with_style({ fg = S.fg }, styles.keywords)

	-------------------------------------------------
	-- GROUPS
	-------------------------------------------------

	return {
		-- -----------------------------------------------
		-- SEMANTIC TOKEN TYPES
		-------------------------------------------------

		["@lsp.type.variable"] = { fg = S.fg },
		["@lsp.type.parameter"] = { fg = S.fg },
		["@lsp.type.property"] = { fg = S.fg },
		["@lsp.type.field"] = { fg = S.fg },
		["@lsp.type.enumMember"] = { fg = S.constant },

		["@lsp.type.function"] = { fg = S.definition },
		["@lsp.type.method"] = { fg = S.definition },
		["@lsp.type.macro"] = { fg = S.definition },

		["@lsp.type.class"] = { fg = S.definition },
		["@lsp.type.struct"] = { fg = S.definition },
		["@lsp.type.interface"] = { fg = S.definition },
		["@lsp.type.type"] = { fg = S.definition },
		["@lsp.type.typeParameter"] = { fg = S.definition },
		["@lsp.type.enum"] = { fg = S.definition },

		["@lsp.type.namespace"] = { fg = S.definition },
		["@lsp.type.module"] = { fg = S.definition },
		["@lsp.type.decorator"] = { fg = S.definition },

		["@lsp.type.string"] = { fg = S.string },
		["@lsp.type.number"] = { fg = S.constant },
		["@lsp.type.boolean"] = { fg = S.constant },

		-- ✅ KEYWORDS (neutral + optional styling)
		["@lsp.type.keyword"] = keyword,

		["@lsp.type.comment"] = { fg = S.comment },
		["@lsp.type.operator"] = { fg = S.fg },
		["@lsp.type.punctuation"] = { fg = S.fg },

		-- -----------------------------------------------
		-- SEMANTIC TOKEN MODIFIERS
		-------------------------------------------------

		["@lsp.mod.deprecated"] = { strikethrough = true },
		["@lsp.mod.readonly"] = { fg = S.constant },
		["@lsp.mod.constant"] = { fg = S.constant },
		["@lsp.mod.defaultLibrary"] = { fg = S.definition },
		["@lsp.mod.static"] = { fg = S.definition },
		["@lsp.mod.async"] = { fg = S.definition },
		["@lsp.mod.documentation"] = { fg = S.comment },
		["@lsp.mod.abstract"] = { fg = S.definition, italic = true },
		["@lsp.mod.modification"] = { fg = S.fg },

		-- -----------------------------------------------
		-- LSP UI GROUPS
		-------------------------------------------------

		LspReferenceText = { bg = S.selection },
		LspReferenceRead = { bg = S.selection },
		LspReferenceWrite = { bg = S.selection },

		LspReferenceTarget = { fg = S.definition, bg = S.selection, bold = true },

		LspCodeLens = { fg = S.comment },
		LspCodeLensSeparator = { fg = S.fg_dark },

		LspInlayHint = { fg = S.comment, bg = S.bg_light },

		LspSignatureActiveParameter = { fg = S.constant, bold = true },
	}
end

return M
