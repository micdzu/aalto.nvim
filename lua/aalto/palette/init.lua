---@module "aalto.palette"
---
--- Palette pipeline for Aalto — the ONLY public entry point for palette construction.
---
--- ---------------------------------------------------------
--- DESIGN OVERVIEW
--- ---------------------------------------------------------
---
--- Aalto separates concerns into four stages:
---
--- raw color definition → base.lua
--- structural variation → variants.lua
--- semantic meaning     → semantic.lua
--- perceptual correction → utils.lua
---
--- IMPORTANT:
--- Accessibility is NOT a separate post-processing pass.
--- It is embedded inside the semantic layer via utils.ensure().
---
--- This ensures:
--- - contrast is role-aware (definition ≠ comment threshold)
--- - palette identity is preserved when colors are close enough
--- - correction happens only when necessary, only where needed
---
--- ---------------------------------------------------------
--- PIPELINE
--- ---------------------------------------------------------
---
--- base → overrides → variants → semantic (→ accessibility)
---
--- 1. base
---    Raw canonical hex colors (non-semantic, not variant-specific)
---
--- 2. overrides
---    User palette overrides injected early (opts.palette)
---
--- 3. variants
---    Light/dark structural transformation + UI layer derivation
---    (bg_light, selection, cursorline)
---
--- 4. semantic
---    Maps raw colors → semantic roles AND applies:
---    - OKLCH-based contrast correction
---    - preserve threshold (soft enforcement)
---    - chroma shaping
---
--- ---------------------------------------------------------
--- USER CONTROL
--- ---------------------------------------------------------
---
--- opts.palette       → raw color overrides (stage 1)
--- opts.variant       → "dark" | "light" | nil (auto from vim.o.background)
--- opts.semantic      → semantic role remapping (stage 4)
--- opts.accessibility → contrast tuning (embedded in stage 4)
---
--- Example — WCAG AA enforcement with preserve threshold:
---
---   accessibility = {
---     enabled  = true,
---     contrast = 4.5,  -- WCAG AA target
---     preserve = 0.93, -- accept colors within 93% of target
---   }
---
--- Example — APCA enforcement:
---
---   accessibility = {
---     enabled  = true,
---     method   = "apca",
---     contrast = 60,   -- Lc 60 ≈ WCAG AA for normal text
---   }
---
--- Example — override specific semantic roles:
---
---   semantic = {
---     definition = "#7C8CFA",
---     string     = "#8FC77C",
---   }
---
--- ---------------------------------------------------------
--- IMPROVEMENT: EARLY CONTRAST FEEDBACK FOR OVERRIDES
--- ---------------------------------------------------------
---
--- Previously, a user could supply a syntactically valid hex color
--- (e.g. "#000001") that would pass validate_options() but then
--- silently trigger a contrast warning deep in the pipeline — far
--- from where the problematic value was defined.
---
--- Now, validate_options() additionally checks that each override
--- color meets a minimum legibility floor against the resolved
--- background. This check is intentionally lenient (floor = 1.5) —
--- it only catches clearly unworkable values, not near-misses.
---
--- The function also validates accessibility.preserve if provided.

local M = {}

-- -----------------------------------------------
-- VALIDATION
-- -----------------------------------------------

---Minimum contrast floor for early override validation.
---Below this value the color is almost certainly invisible.
---This is not a WCAG target — it is a sanity check only.
---@type number
local CONTRAST_FLOOR = 1.5

---Validate user-provided palette options.
---
---Checks:
---  - variant is "dark" or "light" (if provided)
---  - accessibility.contrast is a positive number (if provided)
---  - accessibility.preserve is in (0, 1] (if provided)
---  - accessibility.method is "wcag" or "apca" (if provided)
---  - palette values are valid #RRGGBB hex strings (if provided)
---  - palette values have contrast ≥ CONTRAST_FLOOR against background
---    (early warning only — not a hard error)
---
---@param opts table
---@param bg   string  Resolved background hex (used for contrast floor check)
---@return boolean     valid
---@return string|nil  error_message
local function validate_options(opts, bg)
	if opts.variant and opts.variant ~= "dark" and opts.variant ~= "light" then
		return false, string.format(
			'Invalid variant "%s": must be "dark" or "light"',
			opts.variant
		)
	end

	if opts.accessibility then
		local acc = opts.accessibility

		local contrast = acc.contrast
		if contrast and (type(contrast) ~= "number" or contrast <= 0) then
			return false, "accessibility.contrast must be a positive number"
		end

		local preserve = acc.preserve
		if preserve ~= nil then
			if type(preserve) ~= "number" or preserve <= 0 or preserve > 1 then
				return false, "accessibility.preserve must be a number in (0, 1]"
			end
		end

		local method = acc.method
		if method ~= nil and method ~= "wcag" and method ~= "apca" then
			return false, string.format(
				'accessibility.method "%s" is not valid: must be "wcag" or "apca"',
				tostring(method)
			)
		end
	end

	if opts.palette then
		local utils = require("aalto.palette.utils")

		for key, value in pairs(opts.palette) do
			-- Syntax check: must be a valid #RRGGBB hex string.
			-- (Lua patterns use %x for hex digits, not regex {6}.)
			if type(value) == "string" and not value:match("^#%x%x%x%x%x%x$") then
				return false, string.format(
					'Invalid color for palette.%s: "%s" (expected #RRGGBB)',
					key,
					value
				)
			end

			-- Semantic legibility check: warn early if the color is nearly
			-- invisible against the resolved background. This fires here,
			-- before the value reaches the contrast solver deep in the
			-- pipeline, so the user gets a clear, actionable message.
			--
			-- This is a WARNING (not an error) — the color may still be
			-- intentional (e.g. a low-contrast comment color on dark bg).
			if type(value) == "string" and bg then
				local ratio = utils.contrast(value, bg)
				if ratio < CONTRAST_FLOOR then
					vim.notify(
						string.format(
							"[aalto] palette.%s (%s) has very low contrast against bg (%.2f:1). "
								.. "This color may be nearly invisible. "
								.. "Enable accessibility mode to auto-correct, or choose a different value.",
							key,
							value,
							ratio
						),
						vim.log.levels.WARN
					)
				end
			end
		end
	end

	return true, nil
end

-- -----------------------------------------------
-- BUILD
-- -----------------------------------------------

---Build and return the resolved semantic palette.
---
---@param opts table|nil  Configuration options
---@return table|nil      S — semantic palette, or nil if validation fails
---@return string|nil     error — error message if validation fails
function M.build(opts)
	opts = opts or {}

	local base_mod = require("aalto.palette.base")

	-- Resolve the background early so validate_options() can use it
	-- for the contrast floor check on user-supplied colors.
	-- We use the canonical base bg unless the user has overridden it.
	local resolved_bg = (opts.palette and opts.palette.bg)
		or base_mod.get().bg

	-- Validate inputs before processing
	local valid, err = validate_options(opts, resolved_bg)
	if not valid then
		vim.notify("[aalto] " .. err, vim.log.levels.ERROR)
		return nil, err
	end

	local variants = require("aalto.palette.variants")
	local semantic = require("aalto.palette.semantic")

	-- -----------------------------------------------
	-- 1. BASE + USER PALETTE OVERRIDES
	-- User overrides are injected early so all downstream stages
	-- (variants, semantic, accessibility) see the user's intent.
	-- Defensive copy prevents mutation of base data.
	-------------------------------------------------

	local c = vim.tbl_deep_extend("force", {}, base_mod.get(), opts.palette or {})

	-- -----------------------------------------------
	-- 2. VARIANTS (STRUCTURAL TRANSFORMATIONS)
	-- Applies light/dark switching and derives UI surfaces:
	-- bg_light, selection, cursorline.
	--
	-- Note: variants.apply creates its own defensive copy.
	-------------------------------------------------

	c = variants.apply(c, opts.variant, opts)

	-- -----------------------------------------------
	-- 3. SEMANTIC (MEANING + ACCESSIBILITY)
	-- Maps raw colors → semantic roles and applies
	-- OKLCH-based contrast correction with preserve threshold.
	-------------------------------------------------

	local S = semantic.build(c, opts.semantic or {}, opts)

	return S, nil
end

return M
