---@module "aalto.setup"
---
--- Entry point for Aalto.
---
--- Orchestrates the rendering pipeline:
---
---   base → overrides → variants → semantic → groups
---
--- DESIGN:
--- - no color logic here
--- - purely orchestration + state
--- - deterministic output
---
--- RESPONSIBILITIES:
--- - merge user config
--- - build semantic palette
--- - apply highlights
--- - expose palette/config
--- - optional UI integration (statusline)
---
--- BUG FIXES (vs original):
--- - Removed double `hi clear` from apply(): it was called once in
---   colors/aalto.lua and again here, causing a second syntax reset.
---   hi clear now lives exclusively in colors/aalto.lua.
--- - reload() now caches the original user config (pre-merge) so that
---   re-calling setup() does not double-merge defaults into defaults.
--- - Removed fallback pipeline in build_palette() to ensure consistent
---   validation and avoid duplicated logic.

local M = {}

-- -----------------------------------------------
-- DEFAULT CONFIG
-- -----------------------------------------------

---Default configuration.
---
---Important:
--- - `palette` overrides semantic roles ONLY
--- - `styles` affect rendering, not meaning
--- - `strict` removes all decoration
local defaults = {
	variant = "dark",

	accessibility = {
		enabled = false,
		contrast = 4.5,
	},

	---Semantic overrides (NOT base palette!)
	palette = {},

	---Rendering styles (non-semantic)
	styles = {
		bold = true,
		italic = true,
		comments = { italic = true },
		keywords = {},
		definitions = {},
		types = {},
	},

	---Disable all non-semantic styling
	strict = false,

	---Enable debug output
	debug = false,

	---Transparency
	transparent = false,
	float_transparent = false,

	---User highlight overrides (applied last)
	overrides = {},

	---Auto-enable native statusline
	statusline = false,
}

-- -----------------------------------------------
-- INTERNAL STATE
-- -----------------------------------------------

local config = {}
local current_palette = nil

---Cached raw user config (before merging with defaults).
---Used by reload() to avoid double-merging defaults on repeated calls.
local user_config_cache = nil

-- -----------------------------------------------
-- CONFIG MERGE
-- -----------------------------------------------

---@param user table|nil
---@return table
local function merge(user)
	return vim.tbl_deep_extend("force", {}, defaults, user or {})
end

-- -----------------------------------------------
-- BUILD PALETTE (CONSOLIDATED PIPELINE)
-- -----------------------------------------------

---Build the semantic palette using the canonical pipeline.
---Always uses require("aalto.palette").build to ensure validation.
---@param cfg table
---@return table|nil palette, string|nil error
local function build_palette(cfg)
	local palette_mod = require("aalto.palette")
	return palette_mod.build(cfg)
end

-- -----------------------------------------------
-- APPLY HIGHLIGHTS
-- -----------------------------------------------

---@param palette table
---@param cfg table
local function apply(palette, cfg)
	-- NOTE: We do NOT call `hi clear` here.
	-- It is called once in colors/aalto.lua before setup() is invoked.
	-- Calling it again here would cause a double syntax reset and
	-- potential flicker, and would re-trigger ColorScheme autocommands.

	vim.g.colors_name = "aalto"

	-- Resolve styles
	local styles = vim.tbl_deep_extend("force", {}, defaults.styles, cfg.styles or {})

	if cfg.strict then
		styles.bold = false
		styles.italic = false
		styles.comments = {}
		styles.keywords = {}
		styles.definitions = {}
		styles.types = {}
	end

	-- Apply all groups
	require("aalto.groups").apply(palette, {
		styles = styles,
		strict = cfg.strict,
		transparent = cfg.transparent,
		float_transparent = cfg.float_transparent,
		overrides = cfg.overrides,
	})
end

-- -----------------------------------------------
-- STATUSLINE (AUTO-INTEGRATION)
-- -----------------------------------------------

---Register native Aalto statusline.
---
---Design:
--- - opt-in (statusline = true)
--- - no user boilerplate
--- - uses semantic palette
---
---Safe:
--- - global function defined once
--- - no repeated require overhead
local function setup_statusline(cfg)
	if not cfg.statusline then
		return
	end

	local statusline = require("aalto.statusline")

	-- Define global bridge only once
	if not _G.aalto_statusline then
		_G.aalto_statusline = function()
			return statusline.build(M.get_palette())()
		end
	end

	vim.o.statusline = "%!v:lua.aalto_statusline()"
end

-- -----------------------------------------------
-- DEBUG
-- -----------------------------------------------

---@param p table
local function debug_palette(p)
	vim.notify(vim.inspect(p), vim.log.levels.INFO, {
		title = "Aalto Palette",
	})
end

-- -----------------------------------------------
-- PUBLIC API
-- -----------------------------------------------

---Initialize Aalto colorscheme.
---
---@param user_config table|nil User configuration (see defaults for options)
---@return table|nil palette The resolved semantic palette, nil on error
---@return string|nil error Error message if setup failed
function M.setup(user_config)
	-- Version guard: Neovim 0.9+ recommended for full LSP/treesitter support
	if vim.fn.has("nvim-0.9") == 0 then
		vim.notify(
			"[aalto] Neovim 0.9+ recommended for full LSP semantic token and diagnostic support",
			vim.log.levels.WARN
		)
	end

	-- Clear internal caches to ensure fresh calculations on reload
	require("aalto.palette.utils").clear_cache()

	-- Cache the raw user config BEFORE merging with defaults.
	-- This ensures reload() re-applies only the user's intent,
	-- not defaults that were already baked in from a previous call.
	user_config_cache = user_config

	config = merge(user_config)

	-- Build palette via unified pipeline
	local palette, err = build_palette(config)
	if not palette then
		vim.notify("[aalto] Failed to build palette: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return nil, err
	end

	-- Apply highlights
	apply(palette, config)

	-- Commit state
	current_palette = palette

	-- Optional UI integration
	setup_statusline(config)

	-- Debug output
	if config.debug then
		debug_palette(current_palette)
	end

	return current_palette, nil
end

-- -----------------------------------------------
-- GETTERS
-- -----------------------------------------------

---Get the current semantic palette.
---@return table|nil
function M.get_palette()
	return current_palette
end

---Get the current merged configuration (deep copy).
---@return table
function M.get_config()
	return vim.deepcopy(config)
end

-- -----------------------------------------------
-- RELOAD
-- -----------------------------------------------

---Re-apply the colorscheme using the last user-provided configuration.
---
---Uses the cached raw user config (not the merged config) so that
---defaults are not double-applied on repeated reloads.
function M.reload()
	if user_config_cache ~= nil or (config and next(config)) then
		M.setup(user_config_cache)
	else
		vim.notify("[aalto] Cannot reload: no previous configuration", vim.log.levels.WARN)
	end
end

return M
