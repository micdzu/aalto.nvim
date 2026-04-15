-- colors/aalto.lua
--
-- The bouncer at the door. Neovim loads this file when the user types
-- `:colorscheme aalto`. It clears old highlights, sets the colors_name,
-- and hands control to the real brains in `aalto.setup`.
--
-- NORMAL USAGE — call setup() in your plugin config:
--
--   require("aalto").setup({ variant = "dark" })
--   vim.cmd("colorscheme aalto")
--
-- This file will detect that setup() has already run and skip
-- re-initialisation, so loading the colorscheme is safe to call
-- unconditionally after setup().
--
-- ADVANCED USAGE — vim.g.aalto_config:
--
-- If you need to load the colorscheme before your Lua config runs (e.g.
-- some plugin managers load colorschemes at a fixed early point), you can
-- pass config via a global:
--
--   vim.g.aalto_config = { variant = "light" }
--   vim.cmd("colorscheme aalto")
--
-- Do NOT set vim.g.aalto_config and also call setup() — the two paths are
-- mutually exclusive. setup() always takes precedence; if it has already
-- been called, vim.g.aalto_config is ignored entirely.

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end

vim.g.colors_name = "aalto"

local setup = require("aalto.setup")

-- If setup() has already been called by the user's config, just re-apply
-- the existing palette (e.g. after :colorscheme aalto is run manually or
-- the colorscheme is reloaded by a plugin manager). No config is re-read,
-- no defaults are doubled up.
if setup.get_palette() then
	setup.reload()
	return
end

-- setup() has not been called yet — fall back to vim.g.aalto_config if
-- present, otherwise use defaults.
local raw = vim.g.aalto_config
local config

if raw == nil then
	config = {}
elseif type(raw) == "table" then
	config = raw
else
	vim.notify(
		string.format(
			"[aalto] vim.g.aalto_config must be a table, got %s — using defaults",
			type(raw)
		),
		vim.log.levels.ERROR
	)
	config = {}
end

setup.setup(config)
