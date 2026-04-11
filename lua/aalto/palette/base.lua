---@module "aalto.palette.base"
---
--- Base palette for Aalto.
---
--- This is the canonical source of color identity.
---
--- IMPORTANT:
--- - These are NOT final colors used in highlights.
--- - They are inputs to the rendering pipeline:
---
---   base → variants → semantic → perceptual adjustment
---
--- DESIGN PRINCIPLES:
--- - Dark palette is canonical
--- - Light is DERIVED by variants.lua, not defined here
--- - No contrast tuning here (only identity)
--- - Must remain IMMUTABLE
---
--- BUG FIX (vs original):
--- - M.get() accepted a `variant` parameter but silently ignored it,
---   always returning the dark palette regardless of input.
---   This was misleading: callers passing "light" would receive dark colors
---   with no warning. The parameter has been renamed to `_variant` with an
---   explicit doc comment clarifying that light derivation is handled
---   downstream in variants.lua, not here.

local M = {}

---@class AaltoBasePalette
---@field bg string
---@field fg string
---@field fg_dark string
---@field fg_light string
---@field blue string
---@field green string
---@field magenta string
---@field red string
---@field orange string
---@field cyan string

-------------------------------------------------
-- DARK BASE PALETTE (CANONICAL)
-------------------------------------------------

---@type AaltoBasePalette
local DARK = {
	-------------------------------------------------
	-- CORE SURFACE
	-------------------------------------------------

	bg = "#18153A",

	fg = "#C9C2FF",

	fg_dark = "#746FA3",

	---Bright foreground.
	---
	---IMPORTANT:
	---Previously too bright → broke light mode contrast.
	---Slightly reduced lightness to improve derivation.
	fg_light = "#DAD4FF",

	-------------------------------------------------
	-- ACCENTS
	-------------------------------------------------

	blue = "#7C8CFA",
	green = "#8FC77C",
	magenta = "#B87EDC",

	-------------------------------------------------
	-- EXTENDED
	-------------------------------------------------

	red = "#E87A98",
	orange = "#F0A07A",
	cyan = "#7CD4D1",
}

-------------------------------------------------
-- GET (IMMUTABLE)
-------------------------------------------------

---Return a safe deep copy of the canonical dark base palette.
---
---Why deep copy:
--- Prevents accidental mutation across pipeline stages, which was
--- the root cause of a previous "yellow dark mode" color drift bug.
---
---Why variant is ignored:
--- The dark palette is always canonical. Light mode colors are not
--- separately defined here — they are derived by variants.lua via
--- OKLCH-based lightness inversion and contrast enforcement.
--- Passing "light" here does NOT return light-mode colors; that
--- transformation happens in a later pipeline stage.
---
---@param _variant "dark"|"light"|nil  Accepted but intentionally unused.
---                                    Light derivation is handled by variants.lua.
---@return AaltoBasePalette            A deep copy of the dark base palette.
function M.get(_variant)
	return vim.deepcopy(DARK)
end

return M
