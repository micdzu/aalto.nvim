---@module "aalto.health"
---
--- Health check for Aalto colorscheme.
---
--- Provides:
--- - Current variant and configuration summary
--- - Perceptual invariant validation (with tolerance)
--- - OKLCH color space diagnostics
--- - Light/dark mode contrast comparison
---
--- Usage: :checkhealth aalto

local M = {}

function M.check()
	vim.health.start("Aalto Colorscheme Health Check")

	-- Get current state
	local setup = require("aalto.setup")
	local palette = setup.get_palette()
	local config = setup.get_config()

	if not palette then
		vim.health.error("Aalto is not properly initialized. Did you call require('aalto').setup()?")
		return
	end

	-- Basic info
	vim.health.info(string.format("Current variant: %s", config.variant or "unknown"))
	if config.accessibility and config.accessibility.enabled then
		local method = config.accessibility.method or "wcag"
		local target = config.accessibility.contrast or 4.5
		vim.health.info(string.format("Accessibility mode: ON (method=%s, target=%.1f)", method, target))
	else
		vim.health.info("Accessibility mode: OFF")
	end

	local utils = require("aalto.palette.utils")
	local bg = palette.bg

	-- -----------------------------------------------
	-- 1. PERCEPTUAL INVARIANTS (with tolerance)
	-- -----------------------------------------------

	vim.health.start("Perceptual Invariants")

	-- Definition contrast (should be highest among core syntax roles)
	local def_contrast = utils.contrast(palette.definition, bg)
	vim.health.info(string.format("Definition contrast: %.1f", def_contrast))

	-- Check string contrast relative to definition
	if palette.string then
		local str_contrast = utils.contrast(palette.string, bg)
		local TOLERANCE = 0.2 -- Allow string up to 0.2 above definition without warning

		if str_contrast > def_contrast + TOLERANCE then
			vim.health.warn(
				string.format(
					"String contrast (%.1f) is significantly higher than definition contrast (%.1f) — consider adjusting palette.green",
					str_contrast,
					def_contrast
				)
			)
		elseif str_contrast >= def_contrast then
			vim.health.info(
				string.format(
					"String contrast (%.1f) is similar to definition contrast (%.1f) — hierarchy may be subtle but acceptable",
					str_contrast,
					def_contrast
				)
			)
		end
	end

	-- Check comment contrast (should be lowest)
	if palette.comment then
		local comment_contrast = utils.contrast(palette.comment, bg)
		if comment_contrast >= def_contrast then
			vim.health.warn(
				string.format(
					"Comment contrast (%.1f) is >= definition contrast (%.1f) — comments may be too prominent",
					comment_contrast,
					def_contrast
				)
			)
		else
			vim.health.info(string.format("Comment contrast: %.1f", comment_contrast))
		end
	end

	-- -----------------------------------------------
	-- 2. COLOR SPACE DIAGNOSTICS
	-- -----------------------------------------------

	vim.health.start("Color Space Diagnostics (OKLCH)")

	local gamut_warnings = 0
	for role, hex in pairs(palette) do
		if type(hex) == "string" and hex:match("^#%x%x%x%x%x%x$") then
			local lch = utils.hex_to_oklch(hex)
			local rgb = utils.hex_to_rgb(hex)

			-- Check gamut
			local in_gamut = true
			for _, v in ipairs(rgb) do
				if v < 0 or v > 1 then
					in_gamut = false
					gamut_warnings = gamut_warnings + 1
				end
			end

			local msg = string.format("%s: %s → L=%.3f C=%.3f h=%.0f°", role, hex, lch.L, lch.C, math.deg(lch.h))

			if in_gamut then
				vim.health.info(msg)
			else
				vim.health.warn(msg .. " [OUT OF GAMUT]")
			end
		end
	end

	if gamut_warnings > 0 then
		vim.health.warn(string.format("%d color(s) are out of sRGB gamut — this may cause clipping", gamut_warnings))
	end

	-- -----------------------------------------------
	-- 3. LIGHT/DARK MODE COMPARISON
	-- -----------------------------------------------

	if config.variant == "light" then
		vim.health.start("Light/Dark Mode Comparison")

		-- Build dark palette without applying it (no side effects)
		local palette_mod = require("aalto.palette")
		local dark_config = vim.tbl_deep_extend("force", {}, config, { variant = "dark" })
		local dark_palette, err = palette_mod.build(dark_config)

		if dark_palette then
			for _, role in ipairs({ "definition", "string", "constant", "comment" }) do
				if palette[role] and dark_palette[role] then
					local light_contrast = utils.contrast(palette[role], palette.bg)
					local dark_contrast = utils.contrast(dark_palette[role], dark_palette.bg)
					vim.health.info(
						string.format("%s contrast: %.1f (light) / %.1f (dark)", role, light_contrast, dark_contrast)
					)
				end
			end
		else
			vim.health.warn("Could not generate dark palette for comparison: " .. (err or "unknown"))
		end
	end

	-- -----------------------------------------------
	-- 4. FINAL STATUS
	-- -----------------------------------------------

	vim.health.ok("Aalto health check completed.")
end

return M
