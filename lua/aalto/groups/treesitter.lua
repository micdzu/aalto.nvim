---@module "aalto.groups.treesitter"
---
--- Tree-sitter highlight groups.
---
--- Maps syntax tree captures to Aalto's four semantic roles. The principle:
--- color communicates *category*, not *syntax*. Keywords are scaffolding;
--- only the four roles (definition, constant, string, comment) carry meaning.
---
--- EXCEPTION POLICY
--- ─────────────────
--- Same rule as lsp.lua: deviations require a *behavioral* justification.
--- A reader should behave differently at a glance because of the exception.
---
--- Accepted exceptions (with justification):
---   @markup.heading.1 / .2  → bold
---     Document structure: H1 and H2 are section boundaries that a reader
---     scans for orientation. Bold reinforces the hierarchy that heading
---     levels already imply. H3–H6 use definition color alone — enough to
---     stand out, not enough to compete with top-level structure.
---
---   @markup.italic           → italic
---   @markup.strong           → bold
---   @markup.strikethrough    → strikethrough
---   @markup.underline        → underline
---     These are the author's explicit typographic intent. Ignoring them
---     would actively misrepresent the document.
---
---   @markup.quote            → comment + italic
---     Block quotes are a reader's aside. Comment color recedes them;
---     italic reinforces their "outside the main text" character.
---
---   @markup.list.unchecked   → fg_dark
---   @markup.list.checked     → string (green, conveys "done")
---     Checklist states carry actionable meaning. fg_dark for unchecked
---     reduces visual noise on incomplete items; string (green) for checked
---     is a universally understood "complete" signal.
---
---   @diff.plus  → string   (green: added)
---   @diff.minus → error    (red: removed)
---   @diff.delta → constant (amber: changed)
---     Diff colors are not arbitrary: they map to the nearest semantic role
---     that shares the conventional meaning (green/red/amber for +/-/~).
---     A reader already knows this mapping from every diff tool they have
---     ever used. Overriding it would be perverse.
---
---   @comment.error    → error
---   @comment.warning  → warn
---   @comment.todo     → constant
---   @comment.note     → info
---     Comment annotations carry actionable meaning. Coloring them appropriately
---     makes TODO/FIXME/HACK visible at a glance.

local M = {}

function M.get(S, _, _, opts)
	opts = opts or {}
	local styles = opts.styles or {}

	local link = require("aalto.groups.link").create(S)

	-- Keyword italic flag, resolved once.
	local kw_italic = styles.keywords and styles.keywords.italic or nil

	return {
		-- -------------------------------------------------------------------
		-- Comments
		-- -------------------------------------------------------------------
		["@comment"] = link("comment", styles.comments),
		["@comment.documentation"] = link("comment", styles.comments),
		["@comment.error"] = link("error"), -- FIX, ERROR, BUG
		["@comment.warning"] = link("warn"), -- HACK, WARN, FIXME
		["@comment.todo"] = link("constant"), -- TODO, FIXME, WIP
		["@comment.note"] = link("info"), -- NOTE, INFO, XXX

		-- -------------------------------------------------------------------
		-- Strings and data
		-- -------------------------------------------------------------------
		["@string"] = link("string"),
		["@string.documentation"] = link("comment"), -- docstrings
		["@string.escape"] = link("constant"), -- escape sequences
		["@string.regex"] = link("string"),
		["@string.special"] = link("constant"),
		["@string.special.symbol"] = link("constant"), -- atoms
		["@string.special.path"] = link("string"), -- filenames
		["@string.special.url"] = link("string"), -- URIs

		-- -------------------------------------------------------------------
		-- Characters and constants
		-- -------------------------------------------------------------------
		["@character"] = link("constant"), -- char literals
		["@character.special"] = link("constant"), -- special chars
		["@number"] = link("constant"),
		["@number.float"] = link("constant"),
		["@boolean"] = link("constant"),
		["@constant"] = link("constant"),
		["@constant.builtin"] = link("constant"),
		["@constant.macro"] = link("constant"),

		-- -------------------------------------------------------------------
		-- Definitions — structural landmarks
		-- -------------------------------------------------------------------
		["@function"] = link("definition"),
		["@function.builtin"] = link("definition"),
		["@function.call"] = link("definition"),
		["@function.macro"] = link("definition"), -- preprocessor macros
		["@function.method"] = link("definition"), -- method definitions
		["@function.method.call"] = link("definition"),
		["@method"] = link("definition"),
		["@method.call"] = link("definition"),
		["@constructor"] = link("definition"),
		["@type"] = link("definition"),
		["@type.builtin"] = link("definition"),
		["@type.definition"] = link("definition"),
		["@module"] = link("definition"),
		["@module.builtin"] = link("definition"), -- built-in modules
		["@namespace"] = link("definition"),
		["@label"] = link("definition"),
		["@include"] = link("definition"),
		["@define"] = link("definition"),
		["@macro"] = link("definition"),

		-- -------------------------------------------------------------------
		-- Keywords — scaffolding, not landmarks (neutral foreground)
		-- -------------------------------------------------------------------
		["@keyword"] = { fg = S.fg, italic = kw_italic },
		["@keyword.function"] = { fg = S.fg, italic = kw_italic },
		["@keyword.return"] = { fg = S.fg, italic = kw_italic },
		["@keyword.operator"] = { fg = S.fg, italic = kw_italic },
		["@keyword.import"] = { fg = S.fg, italic = kw_italic },
		["@keyword.type"] = { fg = S.fg, italic = kw_italic },
		["@keyword.modifier"] = { fg = S.fg, italic = kw_italic },
		["@keyword.repeat"] = { fg = S.fg, italic = kw_italic },
		["@keyword.conditional"] = { fg = S.fg, italic = kw_italic },
		["@keyword.exception"] = { fg = S.fg, italic = kw_italic },
		["@keyword.coroutine"] = { fg = S.fg, italic = kw_italic }, -- go, async
		["@keyword.debug"] = { fg = S.fg, italic = kw_italic }, -- debug keywords
		["@keyword.conditional.ternary"] = { fg = S.fg }, -- ?:
		["@keyword.directive"] = { fg = S.fg }, -- shebang
		["@keyword.directive.define"] = { fg = S.fg }, -- #define

		-- -------------------------------------------------------------------
		-- Neutral — binding and reference sites
		-- -------------------------------------------------------------------
		["@variable"] = { fg = S.fg },
		["@variable.builtin"] = { fg = S.fg }, -- self, this, super
		["@variable.parameter"] = { fg = S.fg },
		["@variable.parameter.builtin"] = { fg = S.fg }, -- _, it
		["@variable.member"] = { fg = S.fg },
		["@property"] = { fg = S.fg },
		["@field"] = { fg = S.fg },
		["@attribute"] = { fg = S.fg },
		["@attribute.builtin"] = { fg = S.fg }, -- builtin attrs

		-- -------------------------------------------------------------------
		-- Punctuation and operators
		-- -------------------------------------------------------------------
		["@operator"] = { fg = S.fg },
		["@punctuation"] = { fg = S.fg },
		["@punctuation.bracket"] = { fg = S.fg },
		["@punctuation.delimiter"] = { fg = S.fg },
		["@punctuation.special"] = { fg = S.fg },

		-- -------------------------------------------------------------------
		-- Tags (HTML/XML)
		-- -------------------------------------------------------------------
		["@tag"] = link("definition"),
		["@tag.builtin"] = link("definition"), -- HTML5 tags
		["@tag.attribute"] = { fg = S.fg },
		["@tag.delimiter"] = { fg = S.fg },

		-- -------------------------------------------------------------------
		-- Markup (legacy @markup namespace — keep for older parsers)
		-- -------------------------------------------------------------------
		["@markup.heading"] = link("definition", { bold = true }),
		["@markup.heading.1"] = link("definition", { bold = true }),
		["@markup.heading.2"] = link("definition", { bold = true }),
		["@markup.heading.3"] = link("definition"),
		["@markup.heading.4"] = link("definition"),
		["@markup.heading.5"] = link("definition"),
		["@markup.heading.6"] = link("definition"),

		["@markup.link"] = link("definition"),
		["@markup.link.url"] = link("definition"),
		["@markup.link.label"] = link("definition"),

		["@markup.raw"] = link("constant"),
		["@markup.raw.block"] = link("constant"),

		["@markup.italic"] = { italic = true },
		["@markup.strong"] = { bold = true },
		["@markup.strikethrough"] = { strikethrough = true },
		["@markup.underline"] = { underline = true },

		["@markup.quote"] = link("comment", { italic = true }),

		["@markup.list"] = { fg = S.fg },
		["@markup.list.checked"] = link("string"),
		["@markup.list.unchecked"] = { fg = S.fg_dark },

		["@markup.math"] = link("constant"),

		-- -------------------------------------------------------------------
		-- Markdown (modern @markdown namespace — Neovim 0.10+)
		-- -------------------------------------------------------------------
		["@markdown.heading"] = link("definition", { bold = true }),
		["@markdown.heading.1"] = link("definition", { bold = true }),
		["@markdown.heading.2"] = link("definition", { bold = true }),
		["@markdown.heading.3"] = link("definition"),
		["@markdown.heading.4"] = link("definition"),
		["@markdown.heading.5"] = link("definition"),
		["@markdown.heading.6"] = link("definition"),

		["@markdown.link"] = link("definition"),
		["@markdown.link.url"] = link("definition"),
		["@markdown.link.label"] = link("definition"),

		["@markdown.raw"] = link("constant"),
		["@markdown.raw.block"] = link("constant"),

		["@markdown.italic"] = { italic = true },
		["@markdown.strong"] = { bold = true },
		["@markdown.strikethrough"] = { strikethrough = true },
		["@markdown.underline"] = { underline = true },

		["@markdown.quote"] = link("comment", { italic = true }),

		["@markdown.list"] = { fg = S.fg },
		["@markdown.list.checked"] = link("string"),
		["@markdown.list.unchecked"] = { fg = S.fg_dark },

		["@markdown.math"] = link("constant"),

		-- -------------------------------------------------------------------
		-- Diff (both legacy and modern names)
		-- -------------------------------------------------------------------
		["@diff.plus"] = link("string"), -- green: added
		["@diff.minus"] = link("error"), -- red: removed
		["@diff.delta"] = link("constant"), -- amber: changed

		["@text.diff.add"] = link("string"),
		["@text.diff.delete"] = link("error"),
		["@text.diff.change"] = link("constant"),

		-- -------------------------------------------------------------------
		-- Diagnostics and special
		-- -------------------------------------------------------------------
		["@debug"] = link("warn"),
		["@error"] = link("error"),
		["@preproc"] = { fg = S.fg },

		-- -------------------------------------------------------------------
		-- Special captures (transparent pass-through)
		-- -------------------------------------------------------------------
		["@spell"] = {},
		["@nospell"] = {},
		["@conceal"] = {},

		-- -------------------------------------------------------------------
		-- Language injections
		-- -------------------------------------------------------------------
		["@injection.content"] = {},
		["@injection.language"] = { fg = S.fg_dark },
		["@injection.filename"] = { fg = S.fg_dark },
	}
end

return M
