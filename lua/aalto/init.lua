---@module "aalto"
---
--- Welcome to Aalto's front door.
---
--- This file is what users actually interact with. It exposes a minimal,
--- thoughtful API and registers commands that make runtime tweaking feel
--- like magic (but it's just Lua).
---
--- Commands are registered only once, because duplicate `:AaltoVariant`
--- commands would be like having two light switches for the same bulb—confusing
--- and unnecessary.

local M = {}

-- -----------------------------------------------
-- COMMANDS — because typing is work
-- -----------------------------------------------

local commands_created = false

--- Create user commands. Called automatically after the first `setup()`.
local function create_commands()
	if commands_created then
		return
	end

	local ok_toggle, toggle = pcall(require, "aalto.toggle")
	local ok_setup, setup = pcall(require, "aalto.setup")

	if not ok_toggle or not ok_setup then
		vim.notify("[aalto] Failed to register commands — submodules missing", vim.log.levels.WARN)
		return
	end

	commands_created = true

	-- :AaltoVariant [dark|light]
	vim.api.nvim_create_user_command("AaltoVariant", function(cmd_opts)
		local cfg = setup.get_config() or {}
		if not cfg.variant then
			vim.notify("[aalto] Not initialized — call setup() first", vim.log.levels.ERROR)
			return
		end

		local current = cfg.variant or "dark"
		local new_variant = cmd_opts.args ~= "" and cmd_opts.args or (current == "light" and "dark" or "light")

		if new_variant ~= "dark" and new_variant ~= "light" then
			vim.notify('[aalto] Invalid variant: "' .. new_variant .. '"', vim.log.levels.ERROR)
			return
		end

		local palette, err = setup.update_user_config({ variant = new_variant })
		if not palette then
			vim.notify("[aalto] Failed: " .. (err or "unknown"), vim.log.levels.ERROR)
			return
		end

		vim.notify("[aalto] variant → " .. new_variant, vim.log.levels.INFO)
	end, {
		nargs = "?",
		complete = function()
			return { "dark", "light" }
		end,
		desc = "Toggle or set Aalto variant (dark/light)",
	})

	-- :AaltoStatus
	vim.api.nvim_create_user_command("AaltoStatus", function()
		toggle.status()
	end, { desc = "Show Aalto status" })

	-- :AaltoReload
	vim.api.nvim_create_user_command("AaltoReload", function()
		setup.reload()
		vim.notify("[aalto] Configuration reloaded", vim.log.levels.INFO)
	end, { desc = "Reload Aalto with last used configuration" })

	-- :AaltoPreview [dark|light]
	vim.api.nvim_create_user_command("AaltoPreview", function(cmd_opts)
		local variant = cmd_opts.args
		if variant ~= "dark" and variant ~= "light" then
			vim.notify('[aalto] Preview requires "dark" or "light"', vim.log.levels.ERROR)
			return
		end

		local cfg = setup.get_config()
		if not cfg.variant then
			vim.notify("[aalto] Not initialized — call setup() first", vim.log.levels.ERROR)
			return
		end

		local preview_cfg = vim.tbl_deep_extend("force", {}, cfg, { variant = variant })
		local palette_mod = require("aalto.palette")
		local palette, err = palette_mod.build(preview_cfg)

		if not palette then
			vim.notify("[aalto] Preview failed: " .. (err or "unknown"), vim.log.levels.ERROR)
			return
		end

		require("aalto.groups").apply(palette, preview_cfg)
		vim.notify("[aalto] Previewing " .. variant .. " (use :AaltoVariant to commit)", vim.log.levels.INFO)
	end, {
		nargs = 1,
		complete = function()
			return { "dark", "light" }
		end,
		desc = "Temporarily preview a variant without saving",
	})
end

-- -----------------------------------------------
-- PUBLIC API
-- -----------------------------------------------

--- Initialize Aalto. Call this once, usually in your plugin manager's config.
---@param opts table|nil
---@return table|nil palette
---@return string|nil err
function M.setup(opts)
	local setup = require("aalto.setup")
	local palette, err = setup.setup(opts)
	if not palette then
		return nil, err
	end
	create_commands()
	return palette, nil
end

--- Register custom plugin highlight specs.
---@param specs table[]
function M.register_plugin_specs(specs)
	require("aalto.plugins.spec").register_user_specs(specs)
end

--- Get a lualine-compatible theme table.
---@param opts table|nil
---@return table
function M.lualine_theme(opts)
	local setup = require("aalto.setup")
	local palette = setup.get_palette()
	if not palette then
		vim.notify("[aalto] lualine_theme() called before setup()", vim.log.levels.WARN)
		return {}
	end
	local cfg = setup.get_config() or {}
	local merged = opts and vim.tbl_deep_extend("force", {}, cfg, opts) or cfg
	return require("aalto.groups.plugins").lualine_theme(palette, merged)
end

--- Return the current semantic palette.
---@return table|nil
function M.get_palette()
	return require("aalto.setup").get_palette()
end

return M
