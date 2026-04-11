---@module "aalto.palette.utils"
---
--- Perceptual utilities for Aalto's color system.
---
--- This module provides:
--- - Color space conversions (HEX ↔ RGB ↔ OKLCH)
--- - Contrast calculation (WCAG 2.x and APCA)
--- - Gamut handling and chroma adjustment
--- - Perceptual weight management
--- - Caching for expensive conversions
---
--- All functions are exposed for use in health checks, plugins, and customizations.

local M = {}

-- -----------------------------------------------
-- CACHES FOR PERFORMANCE
-- -----------------------------------------------

---@type table<string, {L:number, C:number, h:number}>
local oklch_cache = {}

---@type table<string, number>
local contrast_cache = {}

-- -----------------------------------------------
-- HEX ↔ RGB CONVERSION
-- -----------------------------------------------

--- Convert hex string to RGB triplet (0–1 range).
---
--- Example:
---   local rgb = M.hex_to_rgb("#7C8CFA")
---   -- returns { 0.486, 0.549, 0.980 }
---
---@param hex string Hex color (e.g., "#7C8CFA")
---@return table {r, g, b} RGB components in 0–1 range
local function hex_to_rgb(hex)
	return {
		tonumber(hex:sub(2, 3), 16) / 255,
		tonumber(hex:sub(4, 5), 16) / 255,
		tonumber(hex:sub(6, 7), 16) / 255,
	}
end

--- Convert RGB triplet (0–1) to hex string.
---
--- Example:
---   local hex = M.rgb_to_hex(0.486, 0.549, 0.980)
---   -- returns "#7C8CFA"
---
---@param r number Red component (0–1)
---@param g number Green component (0–1)
---@param b number Blue component (0–1)
---@return string Hex color string (e.g., "#7C8CFA")
local function rgb_to_hex(r, g, b)
	return string.format(
		"#%02X%02X%02X",
		math.floor(r * 255 + 0.5),
		math.floor(g * 255 + 0.5),
		math.floor(b * 255 + 0.5)
	)
end

-- -----------------------------------------------
-- RGB ↔ LINEAR CONVERSION
-- -----------------------------------------------

--- Convert sRGB component to linear light (gamma correction).
---
--- Used internally for color space conversions.
---
---@param c number sRGB component (0–1)
---@return number Linear light value
local function to_linear(c)
	if c <= 0.04045 then
		return c / 12.92
	else
		return ((c + 0.055) / 1.055) ^ 2.4
	end
end

--- Convert linear light component to sRGB (inverse gamma).
---
--- Used internally for color space conversions.
---
---@param c number Linear light value
---@return number sRGB component (0–1)
local function from_linear(c)
	if c <= 0.0031308 then
		return c * 12.92
	else
		return 1.055 * (c ^ (1 / 2.4)) - 0.055
	end
end

-- -----------------------------------------------
-- OKLCH COLOR SPACE (PUBLIC API)
-- -----------------------------------------------

--- Convert hex string to OKLCH coordinates.
---
--- OKLCH is a perceptual color space where:
--- - L = Lightness (0–1)
--- - C = Chroma (saturation, 0–~0.4 for sRGB)
--- - h = Hue (0–360°)
---
--- Results are cached for performance.
---
--- Example:
---   local lch = M.hex_to_oklch("#7C8CFA")
---   -- returns { L = 0.60, C = 0.15, h = 260.0 }
---
---@param hex string Hex color
---@return table { L, C, h } OKLCH coordinates
function M.hex_to_oklch(hex)
	-- Check cache first
	if oklch_cache[hex] then
		local cached = oklch_cache[hex]
		return { L = cached.L, C = cached.C, h = cached.h }
	end

	local rgb = hex_to_rgb(hex)

	-- Convert RGB to OKLab
	local r, g, b = to_linear(rgb[1]), to_linear(rgb[2]), to_linear(rgb[3])
	local l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
	local m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
	local s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

	l, m, s = l ^ (1 / 3), m ^ (1 / 3), s ^ (1 / 3)

	local L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
	local a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
	local b_val = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s

	local C = math.sqrt(a ^ 2 + b_val ^ 2)
	local h = math.atan2(b_val, a)
	if h < 0 then
		h = h + 2 * math.pi
	end

	-- Cache result
	oklch_cache[hex] = { L = L, C = C, h = h }

	return { L = L, C = C, h = h }
end

--- Convert OKLCH to hex string with sRGB gamut clamping.
---
--- Note: May clamp out-of-gamut colors, causing slight hue shifts.
--- For gamut-safe conversion, use `oklch_to_hex_fitted()`.
---
---@param L number Lightness (0–1)
---@param C number Chroma (typically 0–0.4)
---@param h number Hue in radians (0–2π)
---@return string Hex color
function M.oklch_to_hex(L, C, h)
	local a = C * math.cos(h)
	local b_val = C * math.sin(h)

	-- Convert OKLab to linear RGB
	local l = (L + 0.3963377774 * a + 0.2158037573 * b_val) ^ 3
	local m = (L - 0.1055613458 * a - 0.0638541728 * b_val) ^ 3
	local s = (L - 0.0894841775 * a - 1.2914855480 * b_val) ^ 3

	local r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
	local g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
	local b2 = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

	-- Clamp and convert to sRGB
	r = from_linear(math.max(0, math.min(1, r)))
	g = from_linear(math.max(0, math.min(1, g)))
	b2 = from_linear(math.max(0, math.min(1, b2)))

	return rgb_to_hex(r, g, b2)
end

--- Scale the chroma of a hex color by a factor.
---
--- Useful for implementing perceptual weight differences.
---
--- Example:
---   local more_saturated = M.scale_chroma("#7C8CFA", 1.2)
---
---@param hex string Input hex color
---@param factor number Chroma scale factor (e.g., 1.2 for +20% saturation)
---@return string Adjusted hex color
function M.scale_chroma(hex, factor)
	local lch = M.hex_to_oklch(hex)
	lch.C = math.max(0, lch.C * factor) -- Ensure chroma doesn't go negative
	return M.oklch_to_hex(lch.L, lch.C, lch.h)
end

--- Find the maximum chroma that fits in sRGB gamut at given lightness/hue.
---
--- Used internally by `oklch_to_hex_fitted()` to prevent hue shifts.
---
---@param L number Lightness (0–1)
---@param C number Starting chroma (upper bound)
---@param h number Hue in radians
---@param tolerance number|nil Acceptable chroma delta (default 0.003)
---@return number C_fit In-gamut chroma value
function M.fit_gamut(L, C, h, tolerance)
	tolerance = tolerance or 0.003

	-- Quick check: if already in gamut, return early
	local hex0 = M.oklch_to_hex(L, C, h)
	local lch0 = M.hex_to_oklch(hex0)
	if math.abs(lch0.C - C) <= tolerance then
		return C
	end

	-- Binary search for maximum in-gamut chroma
	local lo = 0.0
	local hi = C
	local best_C = 0.0

	for _ = 1, 18 do -- 18 iterations → ~4e-6 precision
		local mid = (lo + hi) / 2
		local hex = M.oklch_to_hex(L, mid, h)
		local lch2 = M.hex_to_oklch(hex)
		local delta = math.abs(lch2.C - mid)

		if delta <= tolerance then
			best_C = mid
			lo = mid -- in gamut: try higher
		else
			hi = mid -- out of gamut: try lower
		end
	end

	return best_C
end

--- Convert OKLCH to hex with automatic gamut fitting.
---
--- Prevents hue shifts by reducing chroma until the color fits in sRGB.
---
--- Example:
---   local safe_color = M.oklch_to_hex_fitted(0.6, 0.2, math.pi)
---
---@param L number Lightness (0–1)
---@param C number Chroma
---@param h number Hue in radians
---@return string Hex color (guaranteed in gamut)
function M.oklch_to_hex_fitted(L, C, h)
	local C_fit = M.fit_gamut(L, C, h)
	return M.oklch_to_hex(L, C_fit, h)
end

-- -----------------------------------------------
-- CONTRAST CALCULATION (PUBLIC API)
-- -----------------------------------------------

--- Calculate relative luminance (WCAG 2.1).
---
--- Used internally for contrast calculations.
---
---@param hex string Hex color
---@return number Luminance (0–1)
local function luminance(hex)
	local rgb = hex_to_rgb(hex)
	local r, g, b = to_linear(rgb[1]), to_linear(rgb[2]), to_linear(rgb[3])
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

--- Compute WCAG 2.x contrast ratio.
---
--- Reference thresholds:
--- - 4.5: WCAG AA normal text
--- - 7.0: WCAG AAA normal text
--- - 3.0: WCAG AA large text (18pt+)
---
--- Results are cached for performance.
---
--- Example:
---   local ratio = M.contrast("#FFFFFF", "#000000")  -- returns 21.0
---
---@param fg string Hex foreground
---@param bg string Hex background
---@return number Contrast ratio (≥1)
function M.contrast(fg, bg)
	-- Cache key
	local key = fg .. "|" .. bg
	if contrast_cache[key] then
		return contrast_cache[key]
	end

	local L1 = luminance(fg)
	local L2 = luminance(bg)
	if L1 < L2 then
		L1, L2 = L2, L1
	end -- Ensure L1 is lighter
	local ratio = (L1 + 0.05) / (L2 + 0.05)

	contrast_cache[key] = ratio
	return ratio
end

--- Compute APCA contrast (WCAG 3).
---
--- APCA is asymmetric and better matches real-world perception,
--- especially for dark mode.
---
--- Recommended thresholds:
--- - 60: Normal text (≈ WCAG AA)
--- - 75: High contrast (≈ WCAG AAA)
---
---@param fg string Hex foreground
---@param bg string Hex background
---@return number APCA Lc value (0–106)
function M.contrast_apca(fg, bg)
	local function apca_luminance(hex)
		local rgb = hex_to_rgb(hex)
		local r = to_linear(rgb[1])
		local g = to_linear(rgb[2])
		local b = to_linear(rgb[3])
		return 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
	end

	local Y_fg = apca_luminance(fg)
	local Y_bg = apca_luminance(bg)

	-- Soft-clamp near-black values
	local W_offset = 0.027
	Y_fg = Y_fg > W_offset and Y_fg or (Y_fg + (W_offset - Y_fg) ^ 1.33)
	Y_bg = Y_bg > W_offset and Y_bg or (Y_bg + (W_offset - Y_bg) ^ 1.33)

	-- APCA constants
	local N_txt, N_bg = 0.57, 0.56
	local R_txt, R_bg = 0.62, 0.65
	local W_scale = 1.14
	local W_clip = 0.1

	local Lc
	if Y_bg >= Y_fg then
		-- Light background
		Lc = (Y_bg ^ N_bg - Y_fg ^ N_txt) * W_scale
	else
		-- Dark background
		Lc = (Y_bg ^ R_bg - Y_fg ^ R_txt) * W_scale
	end

	return math.abs(Lc) < W_clip and 0 or math.abs(Lc)
end

--- Unified contrast calculation (WCAG or APCA).
---
---@param fg string Hex foreground
---@param bg string Hex background
---@param opts table|nil Configuration (opts.accessibility.method = "apca"|"wcag")
---@return number Contrast value
function M.contrast_for(fg, bg, opts)
	local method = opts and opts.accessibility and opts.accessibility.method
	if method == "apca" then
		return M.contrast_apca(fg, bg)
	end
	return M.contrast(fg, bg) -- default: WCAG
end

-- -----------------------------------------------
-- CONTRAST ADJUSTMENT (PUBLIC API)
-- -----------------------------------------------

--- Adjust a color to meet a contrast target.
---
--- Uses binary search to find the optimal lightness while preserving hue/chroma.
---
---@param hex string Original color
---@param bg string Background color
---@param target number Desired contrast (WCAG ratio or APCA Lc)
---@param opts table|nil Configuration
---@return string Adjusted color (gamut-fitted)
function M.adjust_to_contrast(hex, bg, target, opts)
	opts = opts or {}
	local lch = M.hex_to_oklch(hex)

	local function contrast_at(L)
		local h = M.oklch_to_hex_fitted(L, lch.C, lch.h)
		return M.contrast_for(h, bg, opts)
	end

	local current = contrast_at(lch.L)
	if current >= target then
		return hex
	end

	-- Determine adjustment direction
	local delta = 0.01
	local lighter_contrast = contrast_at(math.min(lch.L + delta, 1.0))
	local increase = lighter_contrast > current

	local low, high = increase and { lch.L, 1.0 } or { 0.0, lch.L }
	local best_L = lch.L

	-- Binary search for optimal lightness
	for _ = 1, 24 do
		local mid = (low + high) / 2
		local c = contrast_at(mid)

		if c >= target then
			best_L = mid
			if increase then
				high = mid
			else
				low = mid
			end
		else
			if increase then
				low = mid
			else
				high = mid
			end
		end
	end

	return M.oklch_to_hex_fitted(best_L, lch.C, lch.h)
end

--- Ensure a color meets contrast requirements.
---
--- Applies adjustments only if accessibility is enabled and the color
--- falls below the target contrast.
---
---@param color string Hex color
---@param bg string Background color
---@param target number|nil Contrast target (defaults to 4.5)
---@param opts table|nil Configuration
---@return string Adjusted color
function M.ensure(color, bg, target, opts)
	opts = opts or {}
	local required = target or (opts.accessibility and opts.accessibility.contrast) or 4.5

	if not (opts.accessibility and opts.accessibility.enabled) then
		return color
	end

	local preserve = (opts.accessibility and opts.accessibility.preserve) or 1.0
	local threshold = required * preserve
	local current = M.contrast_for(color, bg, opts)

	if current >= threshold then
		return color
	end

	return M.adjust_to_contrast(color, bg, required, opts)
end

-- -----------------------------------------------
-- CACHE MANAGEMENT
-- -----------------------------------------------

---Clear all internal caches.
---
---Call this before rebuilding the palette to ensure fresh calculations.
---Useful when base colors may have changed or during testing.
function M.clear_cache()
	oklch_cache = {}
	contrast_cache = {}
end

-- Expose local functions for completeness
M.hex_to_rgb = hex_to_rgb
M.rgb_to_hex = rgb_to_hex
M.to_linear = to_linear
M.from_linear = from_linear

return M
