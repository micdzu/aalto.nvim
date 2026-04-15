---@module "aalto.palette.utils"
---
--- The guts of the perceptual color engine.
---
--- Everything here operates in OKLCH (or OKLab for distance) because
--- HSL is a lie and RGB is a device‑dependent mess. These functions are
--- heavily cached because floating‑point math is expensive and we're not
--- running a supercomputer.
---
--- Public API surface intentionally minimal. Internal helpers are private.

local M = {}

-- -----------------------------------------------
-- CACHES — because converting hex to OKLCH 500 times is silly
-- -----------------------------------------------

local oklch_cache = {}
local contrast_cache = {}

local MAX_CACHE_SIZE = 200

--- Trim a cache when it gets too fat. Removes ~25% of entries arbitrarily.
--- (Yes, pairs() order is "random", but that's fine for a cache.)
local function trim_cache(cache)
	local count = 0
	for _ in pairs(cache) do
		count = count + 1
	end
	if count > MAX_CACHE_SIZE then
		local removed = 0
		local target = math.floor(MAX_CACHE_SIZE * 0.25)
		for k in pairs(cache) do
			cache[k] = nil
			removed = removed + 1
			if removed >= target then
				break
			end
		end
	end
end

-- -----------------------------------------------
-- HEX ↔ RGB (internal, exposed for testing)
-- -----------------------------------------------

local function hex_to_rgb(hex)
	return {
		tonumber(hex:sub(2, 3), 16) / 255,
		tonumber(hex:sub(4, 5), 16) / 255,
		tonumber(hex:sub(6, 7), 16) / 255,
	}
end

local function rgb_to_hex(r, g, b)
	return string.format(
		"#%02X%02X%02X",
		math.floor(r * 255 + 0.5),
		math.floor(g * 255 + 0.5),
		math.floor(b * 255 + 0.5)
	)
end

-- -----------------------------------------------
-- LINEARISATION — because sRGB is nonlinear and our eyes are weird
-- -----------------------------------------------

local function to_linear(c)
	return (c <= 0.04045) and (c / 12.92) or ((c + 0.055) / 1.055) ^ 2.4
end

local function from_linear(c)
	return (c <= 0.0031308) and (c * 12.92) or (1.055 * c ^ (1 / 2.4) - 0.055)
end

-- -----------------------------------------------
-- OKLCH CONVERSION — the star of the show
-- -----------------------------------------------

--- Convert hex to OKLCH. Results are cached.
function M.hex_to_oklch(hex)
	if oklch_cache[hex] then
		return oklch_cache[hex]
	end
	trim_cache(oklch_cache)

	local rgb = hex_to_rgb(hex)
	local r, g, b = to_linear(rgb[1]), to_linear(rgb[2]), to_linear(rgb[3])

	-- Convert to LMS (long, medium, short cone responses)
	local l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
	local m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
	local s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

	-- Nonlinear compression (cube root)
	l, m, s = l ^ (1 / 3), m ^ (1 / 3), s ^ (1 / 3)

	-- OKLab
	local L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
	local a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
	local b_val = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s

	-- OKLCH (cylindrical)
	local C = math.sqrt(a * a + b_val * b_val)
	local h = math.atan2(b_val, a)
	if h < 0 then
		h = h + 2 * math.pi
	end

	local val = { L = L, C = C, h = h }
	oklch_cache[hex] = val
	return val
end

--- Convert OKLCH back to hex. No gamut fitting—may produce out‑of‑gamut colors.
--- For safe conversion, use oklch_to_hex_fitted().
function M.oklch_to_hex(L, C, h)
	local a = C * math.cos(h)
	local b_val = C * math.sin(h)

	local l = (L + 0.3963377774 * a + 0.2158037573 * b_val) ^ 3
	local m = (L - 0.1055613458 * a - 0.0638541728 * b_val) ^ 3
	local s = (L - 0.0894841775 * a - 1.2914855480 * b_val) ^ 3

	local r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
	local g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
	local b2 = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

	r = from_linear(math.max(0, math.min(1, r)))
	g = from_linear(math.max(0, math.min(1, g)))
	b2 = from_linear(math.max(0, math.min(1, b2)))

	return rgb_to_hex(r, g, b2)
end

-- -----------------------------------------------
-- GAMUT FITTING — because not every OKLCH triplet is a valid hex color
-- -----------------------------------------------

--- Find the maximum chroma at a given lightness and hue that fits in sRGB.
--- Uses binary search (16 iterations is plenty for 0.001 precision).
function M.fit_gamut(L, h)
	local lo, hi = 0.0, 0.7
	for _ = 1, 16 do
		local mid = (lo + hi) / 2
		local hex = M.oklch_to_hex(L, mid, h)
		local lch2 = M.hex_to_oklch(hex)
		if math.abs(lch2.C - mid) < 0.001 then
			lo = mid
		else
			hi = mid
		end
	end
	return lo
end

--- Convert OKLCH to hex, automatically reducing chroma if out‑of‑gamut.
function M.oklch_to_hex_fitted(L, C, h)
	local hex = M.oklch_to_hex(L, C, h)
	local back = M.hex_to_oklch(hex)

	-- If round‑trip chroma error is small, we're in gamut
	if math.abs(back.C - C) / math.max(C, 0.001) < 0.005 then
		return hex
	end

	-- Otherwise, find the safe maximum and use 98% of it (safety margin)
	local max_C = M.fit_gamut(L, h)
	local fitted_C = math.min(C, max_C) * 0.98
	return M.oklch_to_hex(L, fitted_C, h)
end

-- -----------------------------------------------
-- CHROMA SCALING — keep saturation in check
-- -----------------------------------------------

--- Scale chroma of a hex color by a factor, respecting gamut limits.
function M.scale_chroma(hex, factor)
	local lch = M.hex_to_oklch(hex)
	local max_C = M.fit_gamut(lch.L, lch.h)
	local new_C = math.min(lch.C * factor, max_C * 0.98)
	return M.oklch_to_hex(lch.L, new_C, lch.h)
end

-- -----------------------------------------------
-- CONTRAST — WCAG 2.x relative luminance
-- -----------------------------------------------

local function luminance(hex)
	local rgb = hex_to_rgb(hex)
	local r, g, b = to_linear(rgb[1]), to_linear(rgb[2]), to_linear(rgb[3])
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

--- Compute WCAG contrast ratio (1–21). Results are cached.
function M.contrast(fg, bg)
	local key = fg .. "|" .. bg
	if contrast_cache[key] then
		return contrast_cache[key]
	end
	trim_cache(contrast_cache)

	local L1, L2 = luminance(fg), luminance(bg)
	if L1 < L2 then
		L1, L2 = L2, L1
	end
	local ratio = (L1 + 0.05) / (L2 + 0.05)
	contrast_cache[key] = ratio
	return ratio
end

-- -----------------------------------------------
-- PERCEPTUAL DISTANCE — how different two colors look
-- -----------------------------------------------

--- Euclidean distance in OKLab space (perceptually uniform).
--- Values around 0.01 are barely noticeable; 0.04–0.08 are distinct.
function M.deltaE_oklch(hex1, hex2)
	local function to_oklab(hex)
		local rgb = hex_to_rgb(hex)
		local r, g, b = to_linear(rgb[1]), to_linear(rgb[2]), to_linear(rgb[3])

		local l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
		local m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
		local s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
		l, m, s = l ^ (1 / 3), m ^ (1 / 3), s ^ (1 / 3)

		return {
			L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
			a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
			b = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
		}
	end

	local c1 = to_oklab(hex1)
	local c2 = to_oklab(hex2)
	local dL = c1.L - c2.L
	local da = c1.a - c2.a
	local db = c1.b - c2.b
	return math.sqrt(dL * dL + da * da + db * db)
end

-- -----------------------------------------------
-- HIERARCHY ENFORCEMENT — the bouncer at the perceptual nightclub
-- -----------------------------------------------

--- A rough importance metric: lightness dominates, chroma adds a bit.
local function importance(lch)
	return lch.L + 0.4 * lch.C
end

--- Ensure that the colors in `colors` follow the order `order` perceptually.
--- Modifies the table in‑place. Used to guarantee definition > constant > string > comment.
---
--- Nudge size is proportional to the gap between adjacent roles rather than
--- fixed. When two roles are far apart the nudge is small (they just need a
--- tiny push to stay separated); when they are close together the nudge is
--- larger so convergence happens in fewer iterations.
---@param colors table   map role -> hex
---@param order table    list of role keys in priority order
---@param variant string "dark"|"light"
---@param bg string      background hex (optional, for contrast checks)
function M.enforce_hierarchy(colors, order, variant, bg)
	local min_delta_L = 0.04 -- minimum lightness gap to feel "different"
	local max_iter = 8 -- slightly more headroom now that nudges are variable
	local is_light = (variant == "light")

	-- Convert to OKLCH for manipulation
	local lch_map = {}
	for _, key in ipairs(order) do
		lch_map[key] = M.hex_to_oklch(colors[key])
	end

	--- Compute a proportional nudge: larger when colors are close, smaller
	--- when they are already well-separated. The 1.5 multiplier ensures we
	--- overshoot the minimum gap slightly so we don't need another iteration
	--- for the same pair.
	local function nudge(gap)
		return math.max(min_delta_L, (min_delta_L - gap) * 1.5)
	end

	for _ = 1, max_iter do
		local changed = false
		for i = 1, #order - 1 do
			local a = lch_map[order[i]]
			local b = lch_map[order[i + 1]]

			-- Calculate importance values ONCE for both ordering checks
			local imp_a = importance(a)
			local imp_b = importance(b)
			local imp_gap = math.abs(imp_a - imp_b)

			-- Enforce lightness ordering (darker in dark mode = higher L)
			-- Higher importance should be more prominent
			if is_light then
				if imp_a > imp_b then
					a.L = math.max(0, a.L - nudge(imp_gap))
					changed = true
				end
			else
				if imp_a < imp_b then
					a.L = math.min(1, a.L + nudge(imp_gap))
					changed = true
				end
			end

			-- Recalculate after potential L change to catch chroma skews
			local imp_a2 = importance(a)
			local imp_b2 = importance(b)
			local imp_gap2 = math.abs(imp_a2 - imp_b2)

			-- Enforce importance ordering as a secondary check
			if is_light then
				if imp_a2 >= imp_b2 then
					a.L = math.max(0, a.L - nudge(imp_gap2))
					changed = true
				end
			else
				if imp_a2 <= imp_b2 then
					a.L = math.min(1, a.L + nudge(imp_gap2))
					changed = true
				end
			end

			-- Optional: also check actual WCAG contrast if bg provided
			if bg then
				-- Recalculate after all L adjustments
				local ca = M.contrast(M.oklch_to_hex_fitted(a.L, a.C, a.h), bg)
				local cb = M.contrast(M.oklch_to_hex_fitted(b.L, b.C, b.h), bg)
				if ca <= cb then
					-- Contrast gap is dimensionless; map it to a lightness nudge
					-- by treating a contrast delta of 1.0 as equivalent to min_delta_L.
					local contrast_gap = cb - ca
					local l_nudge = math.max(min_delta_L, contrast_gap * min_delta_L)
					if is_light then
						a.L = math.max(0, a.L - l_nudge)
					else
						a.L = math.min(1, a.L + l_nudge)
					end
					changed = true
				end
			end
		end
		if not changed then
			break
		end
	end

	-- Write back to hex, with gamut fitting to handle lightness nudges safely
	for _, key in ipairs(order) do
		local c = lch_map[key]
		colors[key] = M.oklch_to_hex_fitted(c.L, c.C, c.h)
	end

	return colors
end

-- -----------------------------------------------
-- DEBUG HELPERS
-- -----------------------------------------------

--- Check if a hex color is within sRGB gamut.
function M.in_gamut(hex)
	local ok, rgb = pcall(hex_to_rgb, hex)
	if not ok then
		return false
	end
	return rgb[1] >= 0 and rgb[1] <= 1 and rgb[2] >= 0 and rgb[2] <= 1 and rgb[3] >= 0 and rgb[3] <= 1
end

--- Clear all caches (called before rebuilding the palette).
function M.clear_cache()
	oklch_cache = {}
	contrast_cache = {}
end

-- Expose for unit tests (only hex_to_rgb/rgb_to_hex are needed externally)
M.hex_to_rgb = hex_to_rgb
M.rgb_to_hex = rgb_to_hex

return M
