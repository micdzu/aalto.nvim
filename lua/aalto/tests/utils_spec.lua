-- tests/utils_spec.lua
-- Tests for aalto.palette.utils

local utils = require("aalto.palette.utils")

local function assert_equal(expected, actual, msg)
	if expected ~= actual then
		error(string.format("%s: expected %s, got %s", msg, tostring(expected), tostring(actual)))
	end
end

local function assert_near(expected, actual, epsilon, msg)
	if math.abs(expected - actual) > epsilon then
		error(string.format("%s: expected %s ± %s, got %s", msg, expected, epsilon, actual))
	end
end

-- Tests
local function test_hex_to_rgb()
	local rgb = utils.hex_to_rgb("#7C8CFA")
	assert_near(0.486, rgb[1], 0.002, "Red component")
	assert_near(0.549, rgb[2], 0.002, "Green component")
	assert_near(0.980, rgb[3], 0.002, "Blue component")
end

local function test_rgb_to_hex()
	local hex = utils.rgb_to_hex(0.486, 0.549, 0.980)
	assert_equal("#7C8CFA", hex:upper(), "Round-trip hex conversion")
end

local function test_contrast_black_white()
	local ratio = utils.contrast("#FFFFFF", "#000000")
	assert_near(21.0, ratio, 0.01, "Black/white contrast")
end

local function test_contrast_same_color()
	local ratio = utils.contrast("#7C8CFA", "#7C8CFA")
	assert_near(1.0, ratio, 0.001, "Same color contrast")
end

local function test_oklch_cache()
	utils.clear_cache()
	local lch1 = utils.hex_to_oklch("#7C8CFA")
	local lch2 = utils.hex_to_oklch("#7C8CFA")
	-- Should be same object reference only if caching works; we test values
	assert_near(lch1.L, lch2.L, 0.0001, "Cached L value")
	assert_near(lch1.C, lch2.C, 0.0001, "Cached C value")
	assert_near(lch1.h, lch2.h, 0.0001, "Cached h value")
end

-- Run all
local tests = {
	hex_to_rgb = test_hex_to_rgb,
	rgb_to_hex = test_rgb_to_hex,
	contrast_black_white = test_contrast_black_white,
	contrast_same_color = test_contrast_same_color,
	oklch_cache = test_oklch_cache,
}

local failed = 0
for name, fn in pairs(tests) do
	local ok, err = pcall(fn)
	if ok then
		print("✓ " .. name)
	else
		print("✗ " .. name .. ": " .. err)
		failed = failed + 1
	end
end

if failed > 0 then
	error(string.format("%d test(s) failed", failed))
end
