---@module "aalto.palette.base"
---
--- The Villa Mairea palette — materials, not hex codes.
---
--- Alvar Aalto's residence (1939) contrasts deep violet Nordic twilight
--- with warm birch interiors. This palette replicates that dialogue using
--- a restrained, material-driven color set.
---
--- Design constraints:
--- - Every color is a material (birch, copper, moss, terracotta, slate).
--- - Dark and light variants are independent, not inversions.
--- - Saturation is deliberate: present but never neon.
---
--- Technical notes:
--- - All colors are sRGB hex with OKLCH lightness anchored for perceptual hierarchy.
--- - Dark bg L≈0.11 (deep violet), Light bg L≈0.95 (warm cream).

local M = {}

-- ---------------------------------------------------------------------------
-- 🌑 DARK — Winter twilight, interior lit by brass lamps
-- ---------------------------------------------------------------------------
local DARK = {
	-- Background: the void. Deep violet-black, not neutral grey.
	-- OKLCH: L=0.11, C=0.08, h=285°
	bg = "#18122E",

	-- Foreground: birch plywood under warm lamplight. Warm off-white, never cool.
	-- Contrast vs bg: ~14:1
	fg = "#EAE1D8",

	-- Muted foreground: unbleached linen. For comments and secondary text.
	fg_dark = "#706873",

	-- Bright foreground: bleached birch. For emphasized UI elements.
	fg_light = "#F5F0E6",

	-- Structural definition: distant winter sky through tall windows.
	blue = "#6B7FD4",

	-- Constant values: patinated copper. Warm, metallic, desaturated enough to recede.
	magenta = "#B87333",

	-- Ecosystem compatibility: a true muted magenta for plugins that expect it.
	accent_magenta = "#A06AA8",

	-- Strings: deep moss. Grey-green like reindeer lichen on forest stones.
	green = "#7D8F6E",

	-- Errors: terracotta brick. Warm red, muted to avoid alarm fatigue.
	red = "#C46B6B",

	-- Warnings: brass lamp shade lit from within. Warm golden-orange.
	orange = "#D4A373",

	-- Info/Hints: wet Nordic slate. Cool teal that doesn't scream cyan.
	cyan = "#6B9A92",
}

-- ---------------------------------------------------------------------------
-- 🌕 LIGHT — Summer interior, bright birch walls, copper details
-- ---------------------------------------------------------------------------
local LIGHT = {
	-- Background: birch plywood wall. Warm cream with subtle peach undertone.
	bg = "#F2EDE6",

	-- Foreground: deep charcoal with violet shadow. Maintains the "purple identity."
	fg = "#2B2740",

	-- Muted foreground: linen in sunlight.
	fg_dark = "#9A948C",

	-- Bright foreground: violet-grey for secondary text.
	fg_light = "#4A4656",

	-- Definition: deep slate blue. Professional and serious.
	blue = "#5C63C0",

	-- Constant: darkened copper. Same material, in shadow.
	magenta = "#8A5A3C",

	-- Ecosystem compatibility.
	accent_magenta = "#8A5A90",

	-- Strings: forest moss. Darker and richer than dark mode for light mode legibility.
	green = "#61784F",

	-- Errors: dark brick. Aged terracotta.
	red = "#9C4A4A",

	-- Warnings: aged brass. Darker metallic tone.
	orange = "#8A6B4A",

	-- Info/Hints: deep slate. Serious, wet stone.
	cyan = "#4F7A70",
}

-- ---------------------------------------------------------------------------
-- GET — The one public function
-- ---------------------------------------------------------------------------
--- Return a deep copy of the palette for the given variant.
---@param variant "dark"|"light"|nil
---@return table
function M.get(variant)
	if variant == "light" then
		return vim.deepcopy(LIGHT)
	end
	return vim.deepcopy(DARK)
end

return M
