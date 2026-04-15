---@module "aalto.toggle"
---
--- Runtime switcheroo utilities.
---
--- Because sometimes you want to flip between dark and light without
--- restarting Neovim like a caveman.

local M = {}

local function require_initialized()
	local setup = require("aalto.setup")
	local cfg = setup.get_config()
	if not cfg or not next(cfg) then
		vim.notify("[aalto] Not initialized — call setup() first", vim.log.levels.ERROR)
		return nil
	end
	return cfg
end

--- Flip between dark and light.
function M.toggle_variant()
	local cfg = require_initialized()
	if not cfg then
		return
	end
	local setup = require("aalto.setup")
	local next_variant = (cfg.variant or "dark") == "dark" and "light" or "dark"
	local palette, err = setup.update_user_config({ variant = next_variant })
	if not palette then
		vim.notify("[aalto] Failed: " .. (err or "unknown"), vim.log.levels.ERROR)
		return
	end
	vim.notify("[aalto] variant → " .. next_variant, vim.log.levels.INFO)
end

--- Show current config (because you forgot what you set 5 minutes ago).
function M.status()
	local cfg = require_initialized()
	if not cfg then
		return
	end
	local lines = {
		"Aalto status:",
		"  variant          → " .. tostring(cfg.variant or "dark"),
		"  transparent      → " .. tostring(cfg.transparent),
		"  float_transparent→ " .. tostring(cfg.float_transparent),
		"  debug mode       → " .. tostring(cfg.debug),
	}
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

return M
