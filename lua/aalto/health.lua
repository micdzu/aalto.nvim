---@module "aalto.health"
---
--- Health check for Aalto. Run `:checkhealth aalto` to see if your colors
--- are behaving themselves. It reports contrast ratios, gamut issues, and
--- whether the light/dark variants are balanced.

local M = {}

function M.check()
	vim.health.start("Aalto Colorscheme Health Check")

	local setup = require("aalto.setup")
	local palette = setup.get_palette()
	local config = setup.get_config()

	if not palette then
		vim.health.error("Aalto not initialized. Call require('aalto').setup() first.")
		return
	end

	vim.health.info("Variant: " .. tostring(config.variant or "dark"))
	vim.health.info(
		string.format(
			"Transparent: %s | float_transparent: %s",
			tostring(config.transparent),
			tostring(config.float_transparent)
		)
	)

	local utils = require("aalto.palette.utils")
	local bg = palette.bg

	-- Perceptual invariants
	vim.health.start("Perceptual Invariants")
	local def_contrast = utils.contrast(palette.definition, bg)
	vim.health.info(string.format("Definition contrast: %.1f", def_contrast))

	if palette.string then
		local str_contrast = utils.contrast(palette.string, bg)
		if str_contrast > def_contrast + 0.2 then
			vim.health.warn("String contrast higher than definition—hierarchy may be inverted.")
		else
			vim.health.ok(string.format("String contrast: %.1f", str_contrast))
		end
	end

	if palette.comment then
		local com_contrast = utils.contrast(palette.comment, bg)
		if com_contrast >= def_contrast then
			vim.health.warn("Comment contrast >= definition—comments may be too prominent.")
		else
			vim.health.ok(string.format("Comment contrast: %.1f", com_contrast))
		end
	end

	-- Gamut check
	vim.health.start("Color Space Diagnostics (OKLCH)")
	local gamut_warnings = 0
	for role, hex in pairs(palette) do
		if type(hex) == "string" and hex:match("^#%x%x%x%x%x%x$") then
			local lch = utils.hex_to_oklch(hex)
			local msg = string.format("%s: %s → L=%.3f C=%.3f h=%.0f°", role, hex, lch.L, lch.C, math.deg(lch.h))
			if utils.in_gamut(hex) then
				vim.health.info(msg)
			else
				vim.health.warn(msg .. " [OUT OF GAMUT]")
				gamut_warnings = gamut_warnings + 1
			end
		end
	end
	if gamut_warnings > 0 then
		vim.health.warn(string.format("%d color(s) out of sRGB gamut—hue shifts possible.", gamut_warnings))
	else
		vim.health.ok("All colors within sRGB gamut.")
	end

	-- Light/dark comparison
	vim.health.start("Light/Dark Mode Contrast Comparison")
	local palette_mod = require("aalto.palette")
	local dark_cfg = vim.tbl_deep_extend("force", {}, config, { variant = "dark" })
	local light_cfg = vim.tbl_deep_extend("force", {}, config, { variant = "light" })
	local dark_pal, dark_err = palette_mod.build(dark_cfg)
	local light_pal, light_err = palette_mod.build(light_cfg)

	if dark_pal and light_pal then
		vim.health.info(string.format("%-12s | %-8s | %-8s | %-8s", "Role", "Dark", "Light", "Δ"))
		for _, role in ipairs({ "definition", "string", "constant", "comment" }) do
			local dc = utils.contrast(dark_pal[role], dark_pal.bg)
			local lc = utils.contrast(light_pal[role], light_pal.bg)
			vim.health.info(string.format("%-12s | %-8.1f | %-8.1f | %-8.1f", role, dc, lc, math.abs(dc - lc)))
		end
	else
		vim.health.warn("Could not generate comparison: " .. (dark_err or light_err or "unknown"))
	end

	vim.health.ok("Health check completed.")
end

return M
