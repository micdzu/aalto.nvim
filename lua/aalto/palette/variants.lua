---@module "aalto.palette.variants"
---
--- Variant transformations with PERCEPTUAL REBALANCING for light mode.
---
--- Key features:
--- - Light mode reduces contrast targets by 15%
--- - Chroma boosted by 5% in light mode
--- - Lightness clamped to L=0.80 to prevent washout
---
--- This module applies structural changes (dark ↔ light) and derives
--- UI surfaces (bg_light, selection, cursorline) using OKLCH offsets.

local utils = require("aalto.palette.utils")
local M = {}

-- Light mode adjustments
local LIGHT_CONTRAST_FACTOR = 0.85 -- Reduce contrast targets by 15%
local LIGHT_CHROMA_BOOST = 1.05 -- Boost chroma by 5%
local MAX_LIGHTNESS = 0.80 -- Clamp lightness to avoid washout

--- Boost chroma of a color by a factor (wrapper around utils.scale_chroma)
---@param hex string
---@param factor number
---@return string
local function boost_chroma(hex, factor)
	return utils.scale_chroma(hex, factor)
end

--- Clamp lightness of a color to a maximum value
---@param hex string
---@param max_L number Maximum lightness (0-1)
---@return string
local function clamp_lightness(hex, max_L)
	local lch = utils.hex_to_oklch(hex)
	if lch.L > max_L then
		lch.L = max_L
	end
	return utils.oklch_to_hex_fitted(lch.L, lch.C, lch.h)
end

--- Derive light-mode color with perceptual adjustments
---@param src string Source hex color
---@param bg string Background hex color
---@param target_contrast number Original contrast target
---@param opts table Configuration options (passed through to adjust_to_contrast)
---@return string Adjusted hex color
local function derive_light_color(src, bg, target_contrast, opts)
	local chroma_boosted = boost_chroma(src, LIGHT_CHROMA_BOOST)
	local lightness_clamped = clamp_lightness(chroma_boosted, MAX_LIGHTNESS)
	return utils.adjust_to_contrast(lightness_clamped, bg, target_contrast * LIGHT_CONTRAST_FACTOR, opts)
end

--- Configuration for UI surface derivation per variant.
---
--- Each surface entry has:
---   L_offset      → OKLCH lightness delta applied to bg
---   chroma_scale  → multiplier for bg chroma before deriving the surface
local SURFACE_CONFIG = {
	dark = {
		bg_light = { L_offset = 0.08, chroma_scale = 1.0 },
		selection = { L_offset = 0.12, chroma_scale = 1.0 },
		cursorline = { L_offset = 0.04, chroma_scale = 1.0 },
	},
	light = {
		bg_light = { L_offset = -0.06, chroma_scale = 0.30 },
		selection = { L_offset = -0.10, chroma_scale = 0.25 },
		cursorline = { L_offset = -0.03, chroma_scale = 0.30 },
	},
}

--- Apply variant transformations with perceptual guarantees
---@param c table Raw palette (from base + overrides)
---@param variant "dark"|"light"
---@param opts table Configuration
---@return table Transformed palette (includes UI surfaces)
function M.apply(c, variant, opts)
	c = vim.tbl_deep_extend("force", {}, c) -- Work on copy
	local base = require("aalto.palette.base").get()

	if variant == "light" then
		-- Override background if not user-defined
		if not (c.bg and c.bg ~= base.bg) then
			c.bg = "#DDD9E6"
		end

		-- Perceptually rebalance all colors (pass opts to derive_light_color)
		c.fg = derive_light_color(c.fg, c.bg, 4.5, opts)
		c.fg_dark = derive_light_color(c.fg_dark, c.bg, 3.0, opts)
		c.fg_light = derive_light_color(c.fg_light, c.bg, 4.5, opts)

		-- Semantic roles (weights handled later in semantic.lua)
		c.blue = derive_light_color(c.blue, c.bg, 4.5, opts)
		c.green = derive_light_color(c.green, c.bg, 3.2, opts)
		c.magenta = derive_light_color(c.magenta, c.bg, 3.8, opts)
		c.red = derive_light_color(c.red, c.bg, 4.5, opts)
		c.orange = derive_light_color(c.orange, c.bg, 3.8, opts)
		c.cyan = derive_light_color(c.cyan, c.bg, 3.2, opts)
	end

	-- Derive UI surfaces
	local lch = utils.hex_to_oklch(c.bg)
	local config = SURFACE_CONFIG[variant or "dark"]

	local function make_surface(cfg)
		local L = math.max(0, math.min(1, lch.L + cfg.L_offset))
		local C = utils.fit_gamut(L, lch.C * cfg.chroma_scale, lch.h)
		return utils.oklch_to_hex(L, C, lch.h)
	end

	c.bg_light = make_surface(config.bg_light)
	c.selection = make_surface(config.selection)
	c.cursorline = make_surface(config.cursorline)

	return c
end

return M
