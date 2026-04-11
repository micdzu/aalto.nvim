-- colors/aalto.lua
-- Native colorscheme entrypoint for Aalto.
--
-- This file is loaded by Neovim when the user runs:
--   :colorscheme aalto
-- or sets vim.o.colorscheme = "aalto"
--
-- It intentionally does very little:
-- - clears existing highlights (required by Neovim convention)
-- - sets vim.g.colors_name (required by Neovim)
-- - delegates everything else to aalto.setup
--
-- NOTE: hi clear is called ONLY here, not inside setup.lua.
-- Calling it a second time in setup.lua would cause a double-reset
-- and potential flicker. See setup.lua for details.
--
-- ALTERNATIVE ENTRY POINT:
-- Users who want to configure Aalto without calling setup() first
-- (e.g. via a plugin manager that sets colorscheme before config runs)
-- can set vim.g.aalto_config before the colorscheme loads:
--
--   vim.g.aalto_config = { variant = "dark", transparent = true }
--   vim.cmd("colorscheme aalto")
--
-- This is equivalent to require("aalto").setup(opts) followed by
-- vim.cmd("colorscheme aalto"), but works in environments where
-- load order cannot be controlled.

-- Clear existing highlights and reset syntax
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end

-- Set colorscheme name (required by Neovim)
vim.g.colors_name = "aalto"

-- Load user configuration from global variable (optional alternative entry point).
-- Falls back to empty table so setup() uses its own defaults.
local config = vim.g.aalto_config or {}

-- Apply the theme
require("aalto.setup").setup(config)
