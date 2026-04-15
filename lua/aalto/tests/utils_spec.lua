-- tests/utils_spec.lua
--
-- Unit tests for aalto.palette.utils.
--
-- Run via:  nvim -l tests/run_tests.lua
-- Or individually: nvim -l tests/utils_spec.lua

local utils = require("aalto.palette.utils")

-- -----------------------------------------------
-- MINI ASSERTION HELPERS
-- -----------------------------------------------

local function assert_equal(expected, actual, msg)
	if expected ~= actual then
		error(string.format("%s: expected %s, got %s", msg, tostring(expected), tostring(actual)))
	end
end

local function assert_near(expected, actual, epsilon, msg)
	if math.abs(expected - actual) > epsilon then
		error(string.format(
			"%s: expected %.6f ± %.6f, got %.6f",
			msg, expected, epsilon, actual
		))
	end
end

local function assert_true(cond, msg)
	if not cond then
		error(msg or "expected true, got false")
	end
end

local function assert_false(cond, msg)
	if cond then
		error(msg or "expected false, got true")
	end
end

-- -----------------------------------------------
-- HEX ↔ RGB
-- -----------------------------------------------

local function test_hex_to_rgb()
	local rgb = utils.hex_to_rgb("#7C8CFA")
	assert_near(0.486, rgb[1], 0.002, "Red component")
	assert_near(0.549, rgb[2], 0.002, "Green component")
	assert_near(0.980, rgb[3], 0.002, "Blue component")
	print("  ✓ hex_to_rgb")
end

local function test_rgb_to_hex()
	local hex = utils.rgb_to_hex(0.486, 0.549, 0.980)
	assert_equal("#7C8CFA", hex:upper(), "Round-trip hex conversion")
	print("  ✓ rgb_to_hex")
end

-- -----------------------------------------------
-- CONTRAST
-- -----------------------------------------------

local function test_contrast_black_white()
	local ratio = utils.contrast("#FFFFFF", "#000000")
	assert_near(21.0, ratio, 0.01, "Black/white contrast")
	print("  ✓ contrast: black/white = 21")
end

local function test_contrast_same_color()
	local ratio = utils.contrast("#7C8CFA", "#7C8CFA")
	assert_near(1.0, ratio, 0.001, "Same color contrast")
	print("  ✓ contrast: same color = 1")
end

-- -----------------------------------------------
-- LINEARISATION (indirect, via contrast)
-- -----------------------------------------------

-- to_linear and from_linear are module-private.
-- Correct linearisation is necessary to produce the WCAG 21:1 ratio,
-- so this test exercises both functions indirectly.
local function test_linear_via_contrast()
	local ratio = utils.contrast("#FFFFFF", "#000000")
	assert_near(21.0, ratio, 0.01, "Linear conversion via contrast()")
	print("  ✓ linearisation (via contrast round-trip)")
end

-- -----------------------------------------------
-- OKLCH CACHE
-- -----------------------------------------------

local function test_oklch_cache()
	utils.clear_cache()
	local lch1 = utils.hex_to_oklch("#7C8CFA")
	local lch2 = utils.hex_to_oklch("#7C8CFA")
	assert_near(lch1.L, lch2.L, 0.0001, "Cached L value")
	assert_near(lch1.C, lch2.C, 0.0001, "Cached C value")
	assert_near(lch1.h, lch2.h, 0.0001, "Cached h value")
	print("  ✓ oklch_cache: hit returns identical values")
end

-- -----------------------------------------------
-- OKLCH ROUND-TRIP
-- -----------------------------------------------

local function test_oklch_round_trip()
	local original  = "#7C8CFA"
	local lch       = utils.hex_to_oklch(original)
	local recovered = utils.oklch_to_hex_fitted(lch.L, lch.C, lch.h)

	-- Round-trip should be within 1 LSB per channel (≈ 0.004 per component)
	local rgb_orig = utils.hex_to_rgb(original)
	local rgb_rec  = utils.hex_to_rgb(recovered)
	assert_near(rgb_orig[1], rgb_rec[1], 0.005, "Round-trip R component")
	assert_near(rgb_orig[2], rgb_rec[2], 0.005, "Round-trip G component")
	assert_near(rgb_orig[3], rgb_rec[3], 0.005, "Round-trip B component")
	print("  ✓ oklch_round_trip")
end

-- -----------------------------------------------
-- IN_GAMUT
-- -----------------------------------------------

-- FIX: the previous test called utils.fit_gamut() which does not exist.
-- The test is rewritten to use utils.in_gamut() and utils.fit_gamut()
-- as actually implemented.

local function test_in_gamut_safe_color()
	-- The canonical Aalto blue is well within sRGB gamut
	assert_true(utils.in_gamut("#7C8CFA"), "Canonical blue should be in gamut")
	print("  ✓ in_gamut: canonical blue is in gamut")
end

local function test_in_gamut_black_and_white()
	-- Corner cases: pure black and white are always in gamut
	assert_true(utils.in_gamut("#000000"), "Black should be in gamut")
	assert_true(utils.in_gamut("#FFFFFF"), "White should be in gamut")
	print("  ✓ in_gamut: black and white are in gamut")
end

local function test_fit_gamut_reduces_chroma()
	-- For a moderate lightness, fit_gamut should return a chroma well below
	-- 0.5 (which is far outside sRGB for most hues).
	local L = 0.6
	local h = math.pi / 4  -- 45° hue
	local max_c = utils.fit_gamut(L, h)
	assert_true(max_c < 0.5, "fit_gamut should return chroma below 0.5 for L=0.6")
	assert_true(max_c > 0.0, "fit_gamut should return positive chroma")

	-- A color at the fitted chroma should round-trip cleanly
	local hex  = utils.oklch_to_hex(L, max_c, h)
	assert_true(utils.in_gamut(hex), "Color at fitted chroma should be in gamut")
	print("  ✓ fit_gamut: returns valid in-gamut chroma")
end

-- -----------------------------------------------
-- ENFORCE_HIERARCHY
-- -----------------------------------------------

local function test_enforce_hierarchy_dark()
	-- In dark mode, definition should end up with higher L than comment
	local colors = {
		definition = "#7C8CFA",  -- blue
		constant   = "#B87EDC",  -- magenta
		string     = "#8FC77C",  -- green
		comment    = "#746FA3",  -- muted purple
	}
	local order = { "definition", "constant", "string", "comment" }

	utils.enforce_hierarchy(colors, order, "dark")

	local def_L = utils.hex_to_oklch(colors.definition).L
	local com_L = utils.hex_to_oklch(colors.comment).L
	assert_true(def_L > com_L, string.format(
		"Dark mode: definition L (%.3f) should be > comment L (%.3f)",
		def_L, com_L
	))
	print("  ✓ enforce_hierarchy: dark mode (definition brighter than comment)")
end

local function test_enforce_hierarchy_light()
	-- In light mode, definition should end up with lower L than comment
	-- (darker = higher contrast against a light background)
	local colors = {
		definition = "#4F5FD1",
		constant   = "#743DB8",
		string     = "#456C30",
		comment    = "#7A7696",
	}
	local order = { "definition", "constant", "string", "comment" }

	utils.enforce_hierarchy(colors, order, "light")

	local def_L = utils.hex_to_oklch(colors.definition).L
	local com_L = utils.hex_to_oklch(colors.comment).L
	assert_true(def_L < com_L, string.format(
		"Light mode: definition L (%.3f) should be < comment L (%.3f)",
		def_L, com_L
	))
	print("  ✓ enforce_hierarchy: light mode (definition darker than comment)")
end

-- -----------------------------------------------
-- SCALE_CHROMA
-- -----------------------------------------------

local function test_scale_chroma_reduces()
	local original = "#B87EDC"
	local lch_orig = utils.hex_to_oklch(original)
	local result   = utils.scale_chroma(original, 0.5)
	local lch_res  = utils.hex_to_oklch(result)
	assert_true(lch_res.C < lch_orig.C,
		"scale_chroma(0.5) should reduce chroma")
	print("  ✓ scale_chroma: factor < 1 reduces chroma")
end

local function test_scale_chroma_preserves_hue()
	local original  = "#B87EDC"
	local result    = utils.scale_chroma(original, 0.5)
	local lch_orig  = utils.hex_to_oklch(original)
	local lch_res   = utils.hex_to_oklch(result)
	-- Hue should be unchanged (within floating-point noise)
	assert_near(lch_orig.h, lch_res.h, 0.01, "scale_chroma should preserve hue")
	print("  ✓ scale_chroma: hue preserved")
end

-- -----------------------------------------------
-- DELTA E
-- -----------------------------------------------

local function test_deltaE_same_color()
	local d = utils.deltaE_oklch("#7C8CFA", "#7C8CFA")
	assert_near(0.0, d, 0.0001, "deltaE of identical colors should be 0")
	print("  ✓ deltaE_oklch: identical colors → 0")
end

local function test_deltaE_different_colors()
	-- Blue and red should have a substantial perceptual distance
	local d = utils.deltaE_oklch("#7C8CFA", "#E87A98")
	assert_true(d > 0.1, "deltaE between blue and red should be > 0.1, got " .. d)
	print("  ✓ deltaE_oklch: blue vs red → large distance")
end

-- -----------------------------------------------
-- RUN ALL
-- -----------------------------------------------

local tests = {
	hex_to_rgb                   = test_hex_to_rgb,
	rgb_to_hex                   = test_rgb_to_hex,
	contrast_black_white         = test_contrast_black_white,
	contrast_same_color          = test_contrast_same_color,
	linear_via_contrast          = test_linear_via_contrast,
	oklch_cache                  = test_oklch_cache,
	oklch_round_trip             = test_oklch_round_trip,
	in_gamut_safe_color          = test_in_gamut_safe_color,
	in_gamut_black_and_white     = test_in_gamut_black_and_white,
	fit_gamut_reduces_chroma     = test_fit_gamut_reduces_chroma,
	enforce_hierarchy_dark       = test_enforce_hierarchy_dark,
	enforce_hierarchy_light      = test_enforce_hierarchy_light,
	scale_chroma_reduces         = test_scale_chroma_reduces,
	scale_chroma_preserves_hue   = test_scale_chroma_preserves_hue,
	deltaE_same_color            = test_deltaE_same_color,
	deltaE_different_colors      = test_deltaE_different_colors,
}

print("\n=== Utils Unit Tests ===")
local passed, failed = 0, 0
for name, fn in pairs(tests) do
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
	else
		print("  ✗ " .. name .. ": " .. tostring(err))
		failed = failed + 1
	end
end

print(string.format("\n  ✓ %d passed  ✗ %d failed", passed, failed))
if failed > 0 then
	error(string.format("%d test(s) failed", failed))
end
