---@module "aalto.setup"
---
--- The conductor of the Aalto orchestra.
---
--- Manages configuration, state, and the entire rendering pipeline.
--- It caches the raw user config so `reload()` doesn't double‑apply defaults.
--- (Defaults are like salt: you only want to add them once.)

local M = {}

-- -----------------------------------------------
-- DEFAULTS — the baseline experience
-- -----------------------------------------------

local defaults = {
	variant = "dark",
	palette = {},
	semantic = {},
	styles = {
		comments = { italic = true },
		keywords = {},
	},
	transparent = false,
	float_transparent = false,
	terminal_colors = true,
	statusline = false,
	overrides = {},
	debug = false,
}

-- -----------------------------------------------
-- INTERNAL STATE
-- -----------------------------------------------

local config = {} -- fully merged config
local current_palette = nil -- cached semantic palette
local user_config_cache = nil -- raw user config (no defaults)
local _initialized = false

-- -----------------------------------------------
-- CONFIG MERGING
-- -----------------------------------------------

local function merge(user)
	return vim.tbl_deep_extend("force", {}, defaults, user or {})
end

-- -----------------------------------------------
-- VALIDATION — catch nonsense early
-- -----------------------------------------------

local function validate_user_config(user)
	if user == nil then
		return true, nil
	end
	if type(user) ~= "table" then
		return false, string.format("[aalto] setup() expects a table or nil, got %s", type(user))
	end
	if user.variant and user.variant ~= "dark" and user.variant ~= "light" then
		return false, string.format('[aalto] invalid variant "%s"', tostring(user.variant))
	end
	if user.overrides and type(user.overrides) ~= "table" then
		return false, "[aalto] overrides must be a table"
	end
	return true, nil
end

-- -----------------------------------------------
-- PALETTE BUILDING
-- -----------------------------------------------

local function build_palette(cfg)
	local ok, palette = pcall(require, "aalto.palette")
	if not ok then
		return nil, "failed to load palette module"
	end
	if type(palette.build) ~= "function" then
		return nil, "palette.build missing"
	end
	return palette.build(cfg)
end

-- -----------------------------------------------
-- HIGHLIGHT APPLICATION
-- -----------------------------------------------

local function apply_highlights(palette, cfg)
	local styles = vim.tbl_deep_extend("force", {}, defaults.styles, cfg.styles or {})
	local groups = require("aalto.groups").get(palette, {
		styles = styles,
		transparent = cfg.transparent,
		float_transparent = cfg.float_transparent,
		overrides = cfg.overrides,
		debug = cfg.debug,
	})
	for name, spec in pairs(groups) do
		pcall(vim.api.nvim_set_hl, 0, name, spec)
	end
end

-- -----------------------------------------------
-- TERMINAL COLORS — because :terminal deserves love
-- -----------------------------------------------
local function set_terminal_colors(S, cfg)
	if not cfg.terminal_colors then
		return
	end

	-- ----------------------------------
	-- Base anchors
	-- ----------------------------------
	local bg = S.bg
	local bg_light = S.bg_light
	local fg = S.fg
	local fg_dark = S.fg_dark

	-- ----------------------------------
	-- Normal ANSI (0–7)
	-- ----------------------------------
	local normal = {
		bg_light, -- black (surface, not true black)
		S.error, -- red (terracotta)
		S.string, -- green (moss)
		S.warn, -- orange (brass)
		S.definition, -- blue (structure)
		S.constant, -- magenta (copper)
		S.info, -- cyan (slate)
		fg, -- white (birch)
	}

	-- ----------------------------------
	-- Bright ANSI (8–15)
	-- ----------------------------------
	local utils = require("aalto.palette.utils")

	local function brighten(hex)
		local lch = utils.hex_to_oklch(hex)
		lch.L = math.min(0.95, lch.L + 0.08) -- controlled lift
		lch.C = lch.C * 1.10 -- slight chroma boost
		return utils.oklch_to_hex_fitted(lch.L, lch.C, lch.h)
	end

	local bright = {}
	for i = 1, 8 do
		bright[i] = brighten(normal[i])
	end

	-- ----------------------------------
	-- Apply
	-- ----------------------------------
	for i = 1, 8 do
		vim.g["terminal_color_" .. (i - 1)] = normal[i]
		vim.g["terminal_color_" .. (i + 7)] = bright[i]
	end

	-- ----------------------------------
	-- Critical: background + foreground
	-- ----------------------------------
	vim.g.terminal_color_background = bg
	vim.g.terminal_color_foreground = fg
end

-- -----------------------------------------------
-- STATUSLINE — minimal but meaningful
-- -----------------------------------------------

local function setup_statusline(cfg)
	if not cfg.statusline then
		return
	end
	local statusline = require("aalto.statusline")
	if not _G.aalto_statusline then
		_G.aalto_statusline = function()
			local palette = M.get_palette()
			return palette and statusline.render() or ""
		end
	end
	vim.o.statusline = "%!v:lua.aalto_statusline()"
	vim.api.nvim_create_autocmd("User", {
		pattern = "GitSignsUpdate",
		callback = function()
			vim.cmd("redrawstatus")
		end,
	})
end

-- -----------------------------------------------
-- PUBLIC API
-- -----------------------------------------------

function M.setup(user_config)
	local ok, err = validate_user_config(user_config)
	if not ok then
		vim.notify(err, vim.log.levels.ERROR)
		return nil, err
	end

	if vim.fn.has("nvim-0.9") == 0 then
		vim.notify("[aalto] Neovim 0.9+ recommended", vim.log.levels.WARN)
	end

	-- Clear caches and user specs to start fresh
	-- AFTER
	-- Clear caches and user specs to start fresh.
	-- NOTE: any register_plugin_specs() calls made after the previous setup()
	-- are cleared here. The documented contract is: call register_plugin_specs()
	-- before setup(), or call reload() after. We surface a warning in debug mode
	-- so the ordering footgun is visible.
	require("aalto.palette.utils").clear_cache()
	local spec_mod = require("aalto.plugins.spec")
	if config and spec_mod._registered_after_setup and (user_config ~= user_config_cache) then
		if (user_config or {}).debug or (config or {}).debug then
			vim.notify(
				"[aalto] setup() called again after register_plugin_specs() — "
					.. "user specs have been cleared. Call register_plugin_specs() "
					.. "before setup(), or use reload() to re-apply.",
				vim.log.levels.WARN
			)
		end
	end
	spec_mod.clear_user_specs()

	user_config_cache = user_config
	config = merge(user_config)

	local palette, build_err = build_palette(config)
	if not palette then
		vim.notify("[aalto] Palette build failed: " .. (build_err or "unknown"), vim.log.levels.ERROR)
		return nil, build_err
	end

	apply_highlights(palette, config)
	set_terminal_colors(palette, config)
	setup_statusline(config)

	current_palette = palette
	_initialized = true

	if config.debug then
		vim.notify(vim.inspect(palette), vim.log.levels.INFO, { title = "Aalto Palette" })
	end

	return palette, nil
end

function M.get_palette()
	return current_palette
end

function M.get_config()
	return vim.deepcopy(config)
end

function M.update_user_config(patch)
	local next_user = vim.tbl_deep_extend("force", {}, user_config_cache or {}, patch)
	return M.setup(next_user)
end

function M.reload()
	if not _initialized then
		vim.notify("[aalto] Cannot reload: setup() hasn't been called", vim.log.levels.WARN)
		return
	end
	M.setup(user_config_cache)
end

return M
