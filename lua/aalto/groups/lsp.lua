---@module "aalto.groups.lsp"
---
--- LSP semantic token highlight groups.
---
--- The LSP knows what things *are* with more precision than Treesitter, so
--- its tokens take priority. However, Aalto still maps everything to the same
--- four semantic roles — the extra LSP precision is used to *correctly assign*
--- roles, not to introduce new visual categories.
---
--- EXCEPTION POLICY
--- ─────────────────
--- Deviations from the four-role system are permitted only when an attribute
--- changes *how a reader should interact with the code*, not merely what the
--- code happens to be. The bar is: would a reader behave differently at a
--- glance if they saw this modifier?
---
--- Accepted exceptions (with justification):
---   @lsp.mod.deprecated  → strikethrough
---     "Do not use this." A reader should immediately know to look elsewhere.
---     Strikethrough is a direct visual metaphor for "crossed out."
---
---   @lsp.type.parameter  → neutral fg (not definition)
---   @lsp.type.variable   → neutral fg (not definition)
---   @lsp.type.property   → neutral fg (not definition)
---     These are *binding sites* and *reference sites*, not structural
---     declarations. Coloring them as definitions would make every variable
---     reference look like a function or type definition, which inverts the
---     hierarchy. They are part of the code's fabric, not its landmarks.
---
--- Rejected exceptions:
---   @lsp.mod.abstract    → italic was here before; removed.
---     "Abstract" is a type-system concept. It does not change how you read
---     or use the identifier at a glance in the way "deprecated" does.
---   @lsp.mod.async       → was definition; stays definition.
---     Async is a property of the function, not a separate semantic role.

local M = {}

function M.get(S, _, _, opts)
	opts = opts or {}
	local styles = opts.styles or {}

	local link = require("aalto.groups.link").create(S)

	-- Keyword italic flag, resolved once.
	local kw_italic = styles.keywords and styles.keywords.italic or nil

	local groups = {
		-- -------------------------------------------------------------------
		-- Semantic Token Types → four roles
		-- -------------------------------------------------------------------

		-- Structural / definitional
		["@lsp.type.namespace"] = link("definition"),
		["@lsp.type.type"] = link("definition"),
		["@lsp.type.class"] = link("definition"),
		["@lsp.type.enum"] = link("definition"),
		["@lsp.type.interface"] = link("definition"),
		["@lsp.type.struct"] = link("definition"),
		["@lsp.type.typeParameter"] = link("definition"),
		["@lsp.type.function"] = link("definition"),
		["@lsp.type.method"] = link("definition"),
		["@lsp.type.macro"] = link("definition"),
		["@lsp.type.decorator"] = link("definition"),
		["@lsp.type.event"] = link("definition"), -- Event declarations (TypeScript, C#)

		-- Constant / value
		["@lsp.type.enumMember"] = link("constant"),
		["@lsp.type.number"] = link("constant"),
		["@lsp.type.boolean"] = link("constant"),

		-- String / data
		["@lsp.type.string"] = link("string"),
		["@lsp.type.regexp"] = link("string"),

		-- Comment / context
		["@lsp.type.comment"] = link("comment", styles.comments),

		-- Keyword — neutral foreground, same as editor keywords.
		-- They are scaffolding, not landmarks.
		["@lsp.type.keyword"] = { fg = S.fg, italic = kw_italic },

		-- Neutral — binding and reference sites are not structural landmarks.
		-- See EXCEPTION POLICY above.
		["@lsp.type.parameter"] = { fg = S.fg },
		["@lsp.type.variable"] = { fg = S.fg },
		["@lsp.type.property"] = { fg = S.fg },
		["@lsp.type.operator"] = { fg = S.fg },
		["@lsp.type.modifier"] = { fg = S.fg },

		-- -------------------------------------------------------------------
		-- Semantic Token Modifiers
		-- -------------------------------------------------------------------

		-- Structural modifiers → definition role
		["@lsp.mod.declaration"] = link("definition"),
		["@lsp.mod.definition"] = link("definition"),
		["@lsp.mod.static"] = link("definition"),
		["@lsp.mod.async"] = link("definition"),
		["@lsp.mod.defaultLibrary"] = link("definition"),

		-- Value modifiers → constant role
		["@lsp.mod.readonly"] = link("constant"),

		-- EXCEPTION: deprecated → strikethrough
		-- This changes reader behavior: "do not use this."
		-- No color change needed — the strikethrough carries the message.
		["@lsp.mod.deprecated"] = { strikethrough = true },

		-- Documentation → comment role
		["@lsp.mod.documentation"] = link("comment"),

		-- Neutral modifiers — these describe implementation details that do
		-- not change the semantic role of the identifier.
		["@lsp.mod.modification"] = { fg = S.fg },

		-- -------------------------------------------------------------------
		-- Type+Modifier Combinations (@lsp.typemod.*)
		-- These take precedence over @lsp.type.* when both apply
		-- -------------------------------------------------------------------

		-- async functions remain definition
		["@lsp.typemod.function.async"] = link("definition"),
		["@lsp.typemod.method.async"] = link("definition"),

		-- defaultLibrary items remain their base role
		["@lsp.typemod.function.defaultLibrary"] = link("definition"),
		["@lsp.typemod.type.defaultLibrary"] = link("definition"),
		["@lsp.typemod.class.defaultLibrary"] = link("definition"),

		-- readonly variables are constants
		["@lsp.typemod.variable.readonly"] = link("constant"),
		["@lsp.typemod.parameter.readonly"] = link("constant"),

		-- static members maintain their base type
		["@lsp.typemod.function.static"] = link("definition"),
		["@lsp.typemod.variable.static"] = link("constant"),

		-- -------------------------------------------------------------------
		-- LSP UI Groups
		-- -------------------------------------------------------------------
		LspReferenceText = { bg = S.selection },
		LspReferenceRead = { bg = S.selection },
		LspReferenceWrite = { bg = S.selection },
		LspReferenceTarget = { fg = S.definition, bg = S.selection, bold = true },
		LspCodeLens = { fg = S.comment },
		LspCodeLensSeparator = { fg = S.fg_dark },
		LspInlayHint = { fg = S.comment, bg = S.bg_light },
		LspSignatureActiveParameter = { fg = S.constant, bold = true },
	}

	return groups
end

return M
