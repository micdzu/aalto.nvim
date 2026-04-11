---@module "aalto.palette.semantic"
---
--- Semantic color layer for Aalto with PERCEPTUAL WEIGHTS.
---
--- This module maps raw palette colors → semantic roles while enforcing:
--- - Structure dominance (definition > all)
--- - Non-competition (staggered contrast/chroma)
--- - Comment recession (lowest weight)
--- - Light mode rebalancing
---
--- FIX: Now guarantees all required keys for Tree-sitter/LSP/UI.

local utils = require("aalto.palette.utils")
local M = {}

--- Perceptual weights for semantic roles (0.0–1.0)
local WEIGHT = {
	definition = 1.00, -- Anchor point
	constant = 0.75, -- Noticeable but not dominant
	string = 0.65, -- Distinguishable but soft
	fg = 0.60, -- Neutral reference
	comment = 0.40, -- Receded
}

--- Chroma factors relative to definition (1.0 = same chroma)
local CHROMA_FACTOR = {
	definition = 1.0, -- Baseline
	constant = 1.1, -- Slightly more saturated
	string = 0.9, -- Less saturated
	comment = 0.7, -- Significantly desaturated
}

--- Apply perceptual weight to a color
---@param hex string Input hex color
---@param bg string Background hex color
---@param role string Semantic role
---@param opts table Configuration
---@return string Adjusted hex color
local function apply_weight(hex, bg, role, opts)
	local target_contrast = WEIGHT[role] * (opts.variant == "light" and 3.8 or 4.5)
	local contrasted = utils.ensure(hex, bg, target_contrast, opts)
	return utils.scale_chroma(contrasted, CHROMA_FACTOR[role])
end

--- Semantic role mapping
---@type table<string, string>
local ROLES = {
	definition = "blue",
	string = "green",
	constant = "magenta",
	comment = "fg_dark",
}

--- Build semantic palette with ALL REQUIRED KEYS
---@param c table Resolved palette (after base + variant)
---@param overrides table|nil User overrides
---@param opts table Configuration
---@return table Semantic palette (complete)
function M.build(c, overrides, opts)
	local bg = c.bg
	local S = {}

	-- Core semantic roles (with weights)
	S.definition = apply_weight(c[ROLES.definition], bg, "definition", opts)
	S.constant = apply_weight(c[ROLES.constant], bg, "constant", opts)
	S.string = apply_weight(c[ROLES.string], bg, "string", opts)
	S.comment = apply_weight(c[ROLES.comment], bg, "comment", opts)

	-- Diagnostics (map to semantic roles for consistency)
	S.error = apply_weight(c.red, bg, "definition", opts) -- High visibility
	S.warn = apply_weight(c.orange, bg, "constant", opts)
	S.info = apply_weight(c.cyan, bg, "string", opts)
	S.hint = apply_weight(c.cyan, bg, "comment", opts) -- Low visibility

	-- UI surfaces (MUST be included for UI modules)
	S.bg_light = c.bg_light -- Forwarded from variants.lua
	S.selection = c.selection -- Forwarded from variants.lua
	S.cursorline = c.cursorline -- Forwarded from variants.lua

	-- Foreground colors (used by syntax/plugins)
	S.fg = c.fg
	S.fg_dark = c.fg_dark
	S.fg_light = c.fg_light

	-- Backgrounds
	S.bg = c.bg

	-- User overrides (reapply weights if semantic)
	if overrides then
		for key, value in pairs(overrides) do
			if ROLES[key] then
				S[key] = apply_weight(value, bg, key, opts)
			else
				S[key] = value -- Pass through non-semantic overrides
			end
		end
	end

	return S
end

return M
