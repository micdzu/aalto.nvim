---@module "aalto"
---
--- Public API entrypoint for Aalto.
---
--- Responsibilities:
--- - expose user-facing API (setup, palette, integrations)
--- - register user commands
--- - delegate all logic to setup + submodules
---
--- Exposed functions:
---   M.setup(opts)          → build palette, apply highlights, register commands
---   M.lualine_theme(opts)  → return a lualine-compatible theme table
---   M.get_palette()        → return the current semantic palette

local M = {}

-------------------------------------------------
-- COMMANDS
-------------------------------------------------

---Ensure commands are only created once.
local commands_created = false

---Create user commands (:AaltoVariant, :AaltoAccessibility, :AaltoStatus, :AaltoReload, :AaltoPreview)
local function create_commands()
	if commands_created then
		return
	end
	commands_created = true

	local toggle = require("aalto.toggle")
	local setup = require("aalto.setup")

	-------------------------------------------------
	-- VARIANT
	-------------------------------------------------

	---Toggle or set variant (:AaltoVariant [dark|light])
	vim.api.nvim_create_user_command("AaltoVariant", function(opts)
		local cfg = setup.get_config() or {}

		-- Guard: ensure initialized
		if not cfg.variant then
			vim.notify("[aalto] Not initialized — call setup() first", vim.log.levels.ERROR)
			return
		end

		local current = cfg.variant or "dark"
		local new = opts.args ~= "" and opts.args or (current == "light" and "dark" or "light")

		-- Validate
		if new ~= "dark" and new ~= "light" then
			vim.notify('[aalto] Invalid variant: "' .. new .. '"', vim.log.levels.ERROR)
			return
		end

		-- Build next config without mutating original
		local next_cfg = vim.tbl_deep_extend("force", {}, cfg, {
			variant = new,
		})

		local palette, err = setup.setup(next_cfg)
		if not palette then
			vim.notify("[aalto] Failed: " .. (err or "unknown"), vim.log.levels.ERROR)
			return
		end

		vim.notify("[aalto] variant → " .. new, vim.log.levels.INFO)
	end, {
		nargs = "?",
		complete = function()
			return { "dark", "light" }
		end,
		desc = "Toggle or set Aalto variant (dark/light)",
	})

	-------------------------------------------------
	-- ACCESSIBILITY
	-------------------------------------------------

	---Toggle contrast accessibility mode
	vim.api.nvim_create_user_command("AaltoAccessibility", function()
		toggle.toggle_accessibility()
	end, { desc = "Toggle Aalto accessibility mode" })

	-------------------------------------------------
	-- STATUS
	-------------------------------------------------

	---Print current configuration
	vim.api.nvim_create_user_command("AaltoStatus", function()
		toggle.status()
	end, { desc = "Show Aalto status" })

	-------------------------------------------------
	-- RELOAD (NEW)
	-------------------------------------------------

	---Reload the colorscheme with the last used configuration.
	---Useful after editing the config file.
	vim.api.nvim_create_user_command("AaltoReload", function()
		setup.reload()
		vim.notify("[aalto] Configuration reloaded", vim.log.levels.INFO)
	end, { desc = "Reload Aalto with last used configuration" })

	-------------------------------------------------
	-- PREVIEW (NEW)
	-------------------------------------------------

	---Temporarily preview a variant without saving it.
	---Example: :AaltoPreview light
	vim.api.nvim_create_user_command("AaltoPreview", function(opts)
		local variant = opts.args
		if variant ~= "dark" and variant ~= "light" then
			vim.notify('[aalto] Preview requires "dark" or "light"', vim.log.levels.ERROR)
			return
		end

		local cfg = setup.get_config()
		if not cfg.variant then
			vim.notify("[aalto] Not initialized — call setup() first", vim.log.levels.ERROR)
			return
		end

		-- Build preview config without altering stored state
		local preview_cfg = vim.tbl_deep_extend("force", {}, cfg, { variant = variant })
		local palette_mod = require("aalto.palette")
		local palette, err = palette_mod.build(preview_cfg)
		if not palette then
			vim.notify("[aalto] Preview failed: " .. (err or "unknown"), vim.log.levels.ERROR)
			return
		end

		-- Apply highlights temporarily (config remains unchanged)
		require("aalto.groups").apply(palette, preview_cfg)
		vim.notify("[aalto] Previewing " .. variant .. " variant (not saved)", vim.log.levels.INFO)
	end, {
		nargs = 1,
		complete = function()
			return { "dark", "light" }
		end,
		desc = "Temporarily preview a variant without saving",
	})
end

-------------------------------------------------
-- SETUP
-------------------------------------------------

---Initialize Aalto and apply highlights.
---
---This:
--- - delegates to setup.lua
--- - registers commands (once)
--- - returns palette for integrations
---
---@param opts table|nil User configuration
---@return table|nil palette The resolved semantic palette (nil on error)
---@return string|nil error Error message if setup failed
function M.setup(opts)
	local setup = require("aalto.setup")

	local palette, err = setup.setup(opts)
	if not palette then
		return nil, err
	end

	create_commands()

	return palette, nil
end

-------------------------------------------------
-- LUALINE THEME
-------------------------------------------------

---Return a lualine-compatible theme table.
---
---Must be called after setup(), or pass opts explicitly.
---
---@param opts table|nil Override opts
---@return table lualine_theme (empty if palette not available)
function M.lualine_theme(opts)
	local setup = require("aalto.setup")

	local palette = setup.get_palette()
	if not palette or not palette.definition then
		vim.notify("[aalto] lualine_theme() called before setup()", vim.log.levels.WARN)
		return {}
	end

	local cfg = setup.get_config() or {}
	local merged = opts and vim.tbl_deep_extend("force", {}, cfg, opts) or cfg

	return require("aalto.groups.plugins").lualine_theme(palette, merged)
end

-------------------------------------------------
-- GET PALETTE
-------------------------------------------------

---Return current semantic palette.
---
---Safe for integrations (wezterm, statusline, etc.)
---
---@return table|nil
function M.get_palette()
	return require("aalto.setup").get_palette()
end

return M
