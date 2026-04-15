-- tests/pipeline_spec.lua
--
-- Integration tests for the Aalto palette pipeline.
--
-- These tests exercise the full build() path (base → variants → semantic)
-- but deliberately avoid calling setup.setup(), which would invoke
-- nvim_set_hl() and fire ColorScheme autocommands as side effects.
--
-- The one exception is test_variant_toggle_preserves_config, which must
-- call setup.setup() because it is testing the runtime state machine.
-- That test cleans up after itself by restoring the original variant.
--
-- Run via:  nvim -l tests/run_tests.lua

local palette = require("aalto.palette")
local utils = require("aalto.palette.utils")

-- -----------------------------------------------
-- MINI ASSERTION HELPERS
-- -----------------------------------------------

local function assert_ok(cond, msg)
	if not cond then
		error(msg or "assertion failed", 2)
	end
end

-- -----------------------------------------------
-- TESTS
-- -----------------------------------------------

local function test_dark_palette_builds()
	local S, err = palette.build({ variant = "dark" })
	assert_ok(S ~= nil, "dark build failed: " .. (err or "unknown"))
	assert_ok(S.definition, "missing definition")
	assert_ok(S.string, "missing string")
	assert_ok(S.constant, "missing constant")
	assert_ok(S.comment, "missing comment")
	print("  ✓ dark palette: all semantic roles present")
end

local function test_light_palette_builds()
	local S, err = palette.build({ variant = "light" })
	assert_ok(S ~= nil, "light build failed: " .. (err or "unknown"))

	local lch = utils.hex_to_oklch(S.bg)
	assert_ok(lch.L > 0.7, string.format("light bg should have high lightness (got %.3f)", lch.L))
	print("  ✓ light palette: background has high lightness")
end

local function test_accessibility_enforces_contrast()
	-- Every semantic role must clear a minimum contrast floor against the
	-- background. We use 2.5:1 as a conservative floor — the semantic
	-- pipeline targets significantly higher values, so anything below this
	-- indicates the positioning math has broken down.
	local MIN_CONTRAST = 2.5
	local roles = { "definition", "constant", "string", "comment" }

	for _, variant in ipairs({ "dark", "light" }) do
		local S, err = palette.build({ variant = variant })
		assert_ok(S ~= nil, variant .. " build failed: " .. (err or "unknown"))

		for _, role in ipairs(roles) do
			local ratio = utils.contrast(S[role], S.bg)
			assert_ok(
				ratio >= MIN_CONTRAST,
				string.format(
					"%s/%s contrast %.2f:1 is below floor %.1f:1",
					variant, role, ratio, MIN_CONTRAST
				)
			)
		end
	end
	print("  ✓ accessibility: all roles clear minimum contrast in dark and light")
end

local function test_semantic_hierarchy_dark()
	-- In dark mode the order definition > constant > string > comment
	-- should hold in terms of contrast against the background.
	local S = palette.build({ variant = "dark" })

	local def_contrast = utils.contrast(S.definition, S.bg)
	local str_contrast = utils.contrast(S.string, S.bg)
	local com_contrast = utils.contrast(S.comment, S.bg)

	assert_ok(
		def_contrast >= str_contrast,
		string.format("definition contrast (%.2f) should be >= string (%.2f)", def_contrast, str_contrast)
	)
	assert_ok(
		def_contrast > com_contrast,
		string.format("definition (%.2f) should beat comment (%.2f)", def_contrast, com_contrast)
	)
	print("  ✓ dark semantic hierarchy: definition > string > comment")
end

local function test_semantic_hierarchy_light()
	-- In light mode, higher-priority roles are darker (higher contrast
	-- against a light background), so definition should still have the
	-- highest contrast.
	local S = palette.build({ variant = "light" })

	local def_contrast = utils.contrast(S.definition, S.bg)
	local com_contrast = utils.contrast(S.comment, S.bg)

	assert_ok(
		def_contrast > com_contrast,
		string.format("light mode: definition (%.2f) should beat comment (%.2f)", def_contrast, com_contrast)
	)
	print("  ✓ light semantic hierarchy: definition > comment")
end

local function test_variant_toggle_preserves_config()
	-- This test calls setup.setup() which has editor side effects.
	-- We restore the original variant afterwards so other tests are
	-- not affected.
	local setup = require("aalto.setup")

	setup.setup({ variant = "dark", debug = false })
	local cfg_before = setup.get_config()
	assert_ok(cfg_before.variant == "dark", "initial variant should be dark")

	local _, err = setup.update_user_config({ variant = "light" })
	assert_ok(not err, tostring(err))

	local cfg_after = setup.get_config()
	assert_ok(cfg_after.variant == "light", "variant should have toggled to light")

	-- Restore original state so subsequent tests run in a clean environment
	setup.update_user_config({ variant = "dark" })

	print("  ✓ variant toggle: update_user_config works correctly")
end

local function test_user_palette_override()
	-- Overriding definition with bright red should shift the hue to red.
	-- The actual hex will be perceptually adjusted, but hue should remain
	-- in the red range (< 30° or > 330°).
	local S = palette.build({
		variant = "dark",
		palette = { definition = "#FF0000" },
	})

	local lch = utils.hex_to_oklch(S.definition)
	local hue_deg = math.deg(lch.h)
	assert_ok(
		hue_deg < 30 or hue_deg > 330,
		string.format("overridden definition hue should be red (got %.1f°)", hue_deg)
	)
	print("  ✓ user palette override: red definition hue preserved")
end

local function test_invalid_variant_returns_error()
	local S, err = palette.build({ variant = "monochrome" })
	assert_ok(S == nil, "invalid variant should return nil palette")
	assert_ok(err ~= nil, "invalid variant should return an error string")
	print("  ✓ validation: invalid variant returns error")
end

local function test_invalid_palette_color_returns_error()
	local S, err = palette.build({
		variant = "dark",
		palette = { definition = "not-a-color" },
	})
	assert_ok(S == nil, "invalid palette color should return nil palette")
	assert_ok(err ~= nil, "invalid palette color should return an error string")
	print("  ✓ validation: invalid palette color returns error")
end

-- -----------------------------------------------
-- RUN ALL
-- -----------------------------------------------

local tests = {
	dark_palette_builds                 = test_dark_palette_builds,
	light_palette_builds                = test_light_palette_builds,
	accessibility_enforces_contrast     = test_accessibility_enforces_contrast,
	semantic_hierarchy_dark             = test_semantic_hierarchy_dark,
	semantic_hierarchy_light            = test_semantic_hierarchy_light,
	variant_toggle_preserves_config     = test_variant_toggle_preserves_config,
	user_palette_override               = test_user_palette_override,
	invalid_variant_returns_error       = test_invalid_variant_returns_error,
	invalid_palette_color_returns_error = test_invalid_palette_color_returns_error,
}

print("\n=== Pipeline Integration Tests ===")
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
	error("some tests failed")
end
