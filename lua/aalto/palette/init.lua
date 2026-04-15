---@module "aalto.palette"
---
--- The public entry point for palette construction.
---
--- Pipeline: base → overrides → variants → semantic
---
--- This module also validates user input and emits helpful warnings
--- when you do something silly (like pick a color with 1.2:1 contrast).

local M = {}

-- -----------------------------------------------
-- VALIDATION
-- -----------------------------------------------

local CONTRAST_FLOOR = 1.5 -- below this, you might as well be invisible

--- Validate user options and palette overrides.
--- Returns (valid, error_message, warnings).
local function validate_options(opts, bg)
	local warnings = {}

	-- Variant must be "dark" or "light"
	if opts.variant and opts.variant ~= "dark" and opts.variant ~= "light" then
		return false, string.format('Invalid variant "%s": must be "dark" or "light"', opts.variant), warnings
	end

	-- Palette overrides: must be valid hex colors
	if opts.palette then
		local utils = require("aalto.palette.utils")
		for key, value in pairs(opts.palette) do
			if type(value) == "string" and not value:match("^#%x%x%x%x%x%x$") then
				return false,
					string.format('Invalid color for palette.%s: "%s" (expected #RRGGBB)', key, value),
					warnings
			end

			-- Check contrast floor against the background
			if type(value) == "string" and bg then
				local ratio = utils.contrast(value, bg)
				if ratio < CONTRAST_FLOOR then
					warnings[#warnings + 1] = string.format(
						"palette.%s (%s) has very low contrast against bg (%.2f:1). "
							.. "This color may be nearly invisible. Consider a different value.",
						key,
						value,
						ratio
					)
				end
			end
		end
	end

	return true, nil, warnings
end

-- -----------------------------------------------
-- BUILD
-- -----------------------------------------------

--- Build the final semantic palette.
---@param opts table|nil  user configuration
---@return table|nil S    semantic palette
---@return string|nil err error message if validation fails
function M.build(opts)
	opts = opts or {}

	local base_mod = require("aalto.palette.base")
	local variants = require("aalto.palette.variants")
	local semantic = require("aalto.palette.semantic")

	-- Determine the background for validation (user override or default)
	local resolved_bg = (opts.palette and opts.palette.bg) or base_mod.get(opts.variant).bg

	-- Validate
	local valid, err, warnings = validate_options(opts, resolved_bg)
	if not valid then
		return nil, err
	end
	for _, w in ipairs(warnings) do
		vim.notify("[aalto] " .. w, vim.log.levels.WARN)
	end

	-- 1. Base palette (variant‑aware)
	local c = vim.tbl_deep_extend("force", {}, base_mod.get(opts.variant), opts.palette or {})

	-- 2. Variants — derive UI surfaces
	c = variants.apply(c, opts.variant, opts)

	-- 3. Semantic — the final transformation
	local semantic_overrides = vim.tbl_deep_extend("force", opts.palette or {}, opts.semantic or {})
	local S = semantic.build(c, semantic_overrides, opts)

	return S, nil
end

return M
