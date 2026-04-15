---@module "aalto.palette.semantic"
---
--- The semantic brain of Aalto.
---
--- This is where raw palette colors become *meaningful*. Each role gets a
--- deliberate position in lightness space relative to the background, and
--- chroma is shaped to reinforce the hierarchy. The result is deterministic,
--- predictable, and (hopefully) pleasing.
---
--- No iterative contrast enforcement—we trust the math.

local utils = require("aalto.palette.utils")
local M = {}

-- ---------------------------------------------------------------------------
-- Role definitions
-- ---------------------------------------------------------------------------
-- Each entry defines:
--   weight — controls distance from background (higher = more prominent)
--   chroma — saturation scaling (1.0 = untouched, <1 = muted)
--   base   — which palette key feeds this role
--
-- The weights encode the visual hierarchy: definition > constant > string > comment.
-- The numbers come from squinting at OKLCH lightness values and muttering.

local ROLE = {
	definition = { weight = 1.00, chroma = 1.00, base = "blue" },
	constant = { weight = 0.80, chroma = 0.85, base = "magenta" },
	string = { weight = 0.60, chroma = 0.80, base = "green" },
	comment = { weight = 0.40, chroma = 0.50, base = "fg_dark" },
}

-- ---------------------------------------------------------------------------
-- Signal roles — diagnostics and statuses that need to be seen
-- ---------------------------------------------------------------------------
local SIGNAL = {
	error = { weight = 1.00, base = "red" },
	warn = { weight = 0.85, base = "orange" },
	info = { weight = 0.70, base = "cyan" },
	hint = { weight = 0.55, base = "cyan" },
}

-- ---------------------------------------------------------------------------
-- Lightness positioning — the core of the perceptual model
-- ---------------------------------------------------------------------------
--- Place a color at a specific distance from the background in lightness.
--- Dark themes push colors lighter; light themes push them darker.
---@param hex string   source color
---@param bg string    background color
---@param weight number  role weight (0..1)
---@param variant string "dark"|"light"
---@return string hex
local function position_lightness(hex, bg, weight, variant)
	local lch = utils.hex_to_oklch(hex)
	local bg_lch = utils.hex_to_oklch(bg)

	local direction = (variant == "light") and -1 or 1

	-- The constants were tuned to give a nice spread without clipping.
	local delta = (0.18 + weight * 0.22) * direction
	lch.L = bg_lch.L + delta

	-- Clamp to avoid extreme values that would break conversion.
	lch.L = math.max(0.05, math.min(0.95, lch.L))

	return utils.oklch_to_hex(lch.L, lch.C, lch.h)
end

-- ---------------------------------------------------------------------------
-- Role application — the full transformation for a semantic role
-- ---------------------------------------------------------------------------
local function apply_role(hex, bg, role, opts)
	local variant = opts.variant or "dark"
	local r = ROLE[role]

	-- 1. Position in lightness space (this defines the contrast)
	local color = position_lightness(hex, bg, r.weight, variant)

	-- 2. Scale chroma to control visual intensity
	color = utils.scale_chroma(color, r.chroma)

	-- No accessibility gate—the positioning already ensures adequate contrast.
	return color
end

-- ---------------------------------------------------------------------------
-- Signal application — similar, but with a chroma boost for visibility
-- ---------------------------------------------------------------------------
local function apply_signal(hex, bg, level, opts)
	local variant = opts.variant or "dark"
	local s = SIGNAL[level]

	local color = position_lightness(hex, bg, s.weight, variant)

	-- Signals get a little extra chroma to stand out in UI.
	-- scale_chroma clamps silently at the gamut boundary; in debug mode
	-- we surface a warning so it's clear the boost was absorbed.
	local factor = 1.0 + s.weight * 0.2
	local boosted = utils.scale_chroma(color, factor)

	if opts.debug then
		local before_C = utils.hex_to_oklch(color).C
		local after_C = utils.hex_to_oklch(boosted).C
		local expected_C = before_C * factor
		if (expected_C - after_C) / math.max(expected_C, 0.001) > 0.05 then
			vim.notify(
				string.format(
					"[aalto] signal '%s': chroma boost %.2f clamped by gamut " .. "(%.3f → %.3f, expected %.3f)",
					level,
					factor,
					before_C,
					after_C,
					expected_C
				),
				vim.log.levels.DEBUG
			)
		end
	end

	return boosted
end

-- ---------------------------------------------------------------------------
-- Build the semantic palette
-- ---------------------------------------------------------------------------
---@param c table        base palette (from variants layer)
---@param overrides table user overrides (raw colors)
---@param opts table      configuration (variant, etc.)
---@return table S        semantic palette
function M.build(c, overrides, opts)
	opts = opts or {}
	local bg = c.bg
	local S = {}

	-- 1. Core semantic roles
	for role, spec in pairs(ROLE) do
		S[role] = apply_role(c[spec.base], bg, role, opts)
	end

	-- 2. Signals
	for name, spec in pairs(SIGNAL) do
		S[name] = apply_signal(c[spec.base], bg, name, opts)
	end

	-- 3. UI passthrough — these are already computed by variants
	S.bg = c.bg
	S.bg_light = c.bg_light
	S.selection = c.selection
	S.cursorline = c.cursorline
	S.bg_float = c.bg_float -- from variants

	S.fg = c.fg
	S.fg_dark = c.fg_dark
	S.fg_light = c.fg_light

	-- 4. Overrides — applied raw, with a warning if contrast is too low
	if overrides then
		local variant = opts.variant or "dark"
		local floor = (variant == "light") and 4.8 or 4.2
		for key, value in pairs(overrides) do
			local current = utils.contrast(value, bg)
			if current < floor then
				vim.notify(
					string.format(
						"[aalto] semantic.%s has low contrast (%.2f:1 < %.1f:1) — it may be hard to read",
						key,
						current,
						floor
					),
					vim.log.levels.WARN
				)
			end
			S[key] = value
		end
	end

	-- 5. Enforce perceptual hierarchy — the final safeguard
	utils.enforce_hierarchy(S, {
		"definition",
		"constant",
		"string",
		"comment",
	}, opts.variant or "dark", bg)

	return S
end

return M
