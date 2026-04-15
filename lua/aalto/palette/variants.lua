---@module "aalto.palette.variants"
---
--- UI surface bakery. We take the base background and bake it into slightly
--- different surfaces using precise OKLCH mathematics. It's like making
--- croissants, but with fewer calories and more floating-point errors.

local utils = require("aalto.palette.utils")
local M = {}

-- ---------------------------------------------------------------------------
-- Surface recipes (structural only)
-- ---------------------------------------------------------------------------
-- These numbers were arrived at through rigorous scientific squinting.
-- Adjust them at your own peril; the author accepts no responsibility for
-- resulting existential crises about whether a cursorline is "too bright."

local SURFACE_CONFIG = {
	dark = {
		bg_light = { L_frac = 0.07, chroma_scale = 0.96 }, -- raised, like an eyebrow
		cursorline = { L_frac = 0.06, chroma_scale = 1.00 }, -- subtle, like a sigh
	},
	light = {
		bg_light = { L_frac = 0.08, chroma_scale = 0.30 }, -- barely there, like a cloud's shadow
		cursorline = { L_frac = 0.04, chroma_scale = 0.30 }, -- you'll notice it, but you won't know why
	},
}

-- ---------------------------------------------------------------------------
-- Helpers (the part where math happens)
-- ---------------------------------------------------------------------------

--- Create a structural surface that does not drift in hue.
--- Because hue drift is how you end up with a purple statusline and a sense of regret.
---@param lch table        OKLCH of the background
---@param cfg table        { L_frac, chroma_scale }
---@param available_range number  remaining lightness headroom
---@param is_light boolean
---@return number L, number C, number h
local function make_surface(lch, cfg, available_range, is_light)
	local delta = cfg.L_frac * available_range
	-- Light themes step down; dark themes step up. Opposite day, every day.
	local L = is_light and math.max(0.02, lch.L - delta) or math.min(0.98, lch.L + delta)
	local base_C = math.max(lch.C, 0.02) -- never zero; zero chroma is the color of sadness
	local C = base_C * cfg.chroma_scale
	return L, C, lch.h
end

--- Create a surface at a specific perceptual distance (ΔE) from the background.
--- We now use the proper OKLab distance because hand-rolled approximations are
--- how you end up with a selection color that looks "off" in a way you can't
--- articulate but will blame on poor sleep.
---@param base_hex string  original background hex (anchor)
---@param lch table         OKLCH of background
---@param target_de number  desired ΔE (0.10 is "noticeable but polite")
---@param is_light boolean
---@return number L, number C, number h
local function make_surface_deltaE(base_hex, lch, target_de, is_light)
	local step = 0.01
	local L = lch.L
	local C = math.max(lch.C, 0.02)
	local h = lch.h

	-- 64 iterations is overkill for a color that will be seen for 0.3 seconds
	-- while you highlight a line and immediately change your mind.
	for _ = 1, 64 do
		local newL = is_light and (L - step) or (L + step)
		local candidate_hex = utils.oklch_to_hex_fitted(newL, C, h)
		local de = utils.deltaE_oklch(base_hex, candidate_hex)
		if de >= target_de then
			return newL, C, h
		end
		L = newL
	end
	-- If we get here, we've walked into the void. Return what we have and pray.
	return L, C, h
end

-- ---------------------------------------------------------------------------
-- Apply surface transformations
-- ---------------------------------------------------------------------------
---@param c table           base palette (must include `bg`)
---@param variant "dark"|"light"
---@param _opts table|nil   ignored, but kept for future over-engineering
---@return table            palette with surfaces added
function M.apply(c, variant, _opts)
	-- Deep copy because mutation is the root of all debugging sessions.
	c = vim.tbl_deep_extend("force", {}, c)

	local config = SURFACE_CONFIG[variant or "dark"]
	local lch = utils.hex_to_oklch(c.bg)

	local is_light = (variant == "light")
	local available_range = is_light and lch.L or (1.0 - lch.L)

	-- -----------------------------------------------------------------------
	-- Structural surfaces: stable, predictable, unlikely to startle
	-- -----------------------------------------------------------------------

	local L1, C1, h1 = make_surface(lch, config.bg_light, available_range, is_light)
	c.bg_light = utils.oklch_to_hex_fitted(L1, C1, h1)

	local Lc, Cc, hc = make_surface(lch, config.cursorline, available_range, is_light)
	c.cursorline = utils.oklch_to_hex_fitted(Lc, Cc, hc)

	-- -----------------------------------------------------------------------
	-- Perceptual surfaces: controlled by ΔE, because "a bit lighter" is a vibe
	-- -----------------------------------------------------------------------

	-- Selection: clear separation, but not so clear that it screams at you.
	-- A ΔE of 0.10 is the color equivalent of a raised eyebrow.
	local Ls, Cs, hs = make_surface_deltaE(c.bg, lch, 0.10, is_light)
	c.selection = utils.oklch_to_hex_fitted(Ls, Cs, hs)

	-- Float surfaces inherit from the structural layer because inventing
	-- a fourth background variant would be self-indulgent.
	c.bg_float = c.bg_light

	-- Return the enriched palette. The colors are now slightly different
	-- in ways that matter only to the color engine and insomniacs.
	return c
end

return M
