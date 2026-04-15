---@module "aalto.groups.link"
---
--- The translation layer between semantic roles and actual highlight specs.
--- Think of it as a phrasebook: "definition" → `{ fg = S.definition }`.
---
--- It also sanitizes extra style attributes so you can't accidentally pass
--- `{ font = "Comic Sans" }` and crash Neovim.

local M = {}

local ALLOWED_STYLE_KEYS = {
	bold = true,
	italic = true,
	underline = true,
	undercurl = true,
	strikethrough = true,
	reverse = true,
}

--- Remove any keys that aren't valid highlight attributes.
local function sanitize_style(style)
	if not style then
		return nil
	end
	local clean = {}
	for k, v in pairs(style) do
		if ALLOWED_STYLE_KEYS[k] then
			clean[k] = v
		end
	end
	return next(clean) and clean or nil
end

--- Create a `link` function bound to a specific semantic palette.
---@param S table Semantic palette
---@return function link(role, extra) -> table
function M.create(S)
	-- Base specs—the bare minimum for each role.
	local ROLE_SPEC = {
		-- Semantic roles (foreground only)
		definition = { fg = S.definition },
		constant = { fg = S.constant },
		string = { fg = S.string },
		comment = { fg = S.comment },

		-- Signals
		error = { fg = S.error },
		warn = { fg = S.warn },
		info = { fg = S.info },
		hint = { fg = S.hint },

		-- Neutrals
		fg = { fg = S.fg },
		subtle = { fg = S.fg_dark },

		-- Inverted roles (for search, visual bell, etc.)
		inv_definition = { fg = S.bg, bg = S.definition },
		inv_constant = { fg = S.bg, bg = S.constant },
		inv_string = { fg = S.bg, bg = S.string },
		inv_comment = { fg = S.bg, bg = S.comment },
	}

	return function(role, extra)
		local base = ROLE_SPEC[role]
		if not base then
			vim.notify("[aalto] unknown role: " .. tostring(role), vim.log.levels.ERROR)
			return {}
		end

		-- Start with a copy so we don't mutate the base spec.
		local hl = vim.deepcopy(base)

		local clean = sanitize_style(extra)
		if clean then
			for k, v in pairs(clean) do
				hl[k] = v
			end
		end

		return hl
	end
end

return M
