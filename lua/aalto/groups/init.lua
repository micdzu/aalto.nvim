---@module "aalto.groups"
---
--- The great aggregator. Takes the semantic palette, passes it through
--- each layer of highlight definitions, and spits out a flat table of
--- Neovim highlight groups. The order is sacred: editor → treesitter → lsp → plugins → overrides.
--- Later layers win, because LSP knows more than Treesitter, and the user knows best.

local M = {}

-------------------------------------------------
-- Utilities
-------------------------------------------------

--- Safe require—returns nil if the module is missing instead of exploding.
local function safe_require(name)
	local ok, mod = pcall(require, name)
	return ok and mod or nil
end

--- Merge highlight groups, with optional debug spam when keys collide.
---@param dst table
---@param src table|nil
---@param label string
---@param debug boolean
local function merge(dst, src, label, debug)
	if not src then
		return
	end
	for k, v in pairs(src) do
		if debug and dst[k] ~= nil then
			vim.notify(string.format("[aalto] override: %s (%s)", k, label), vim.log.levels.DEBUG)
		end
		dst[k] = v
	end
end

-------------------------------------------------
-- Main entry
-------------------------------------------------

--- Build the final highlight group table.
---@param S table   Semantic palette
---@param opts table User options (styles, transparency, overrides, debug)
---@return table groups
function M.get(S, opts)
	opts = opts or {}
	local debug = opts.debug or false

	-- Resolve transparency once—submodules get clean values
	local bg = opts.transparent and "NONE" or S.bg
	local bg_float = opts.float_transparent and "NONE" or S.bg_float

	local groups = {}

	-- 1. Editor — the foundation
	local editor = safe_require("aalto.groups.editor")
	if editor then
		merge(groups, editor.get(S, bg, bg_float, opts), "editor", debug)
	end

	-- 2. Treesitter — syntax enrichment
	local ts = safe_require("aalto.groups.treesitter")
	if ts then
		merge(groups, ts.get(S, bg, bg_float, opts), "treesitter", debug)
	end

	-- 3. LSP — semantic tokens (highest built‑in priority)
	local lsp = safe_require("aalto.groups.lsp")
	if lsp then
		merge(groups, lsp.get(S, bg, bg_float, opts), "lsp", debug)
	end

	-- 4. Plugins — third‑party integrations
	local plugins = safe_require("aalto.groups.plugins")
	if plugins then
		merge(groups, plugins.get(S, bg, bg_float, opts), "plugins", debug)
	end

	-- 5. User overrides — the final word
	if type(opts.overrides) == "function" then
		local ok, user = pcall(opts.overrides, S)
		if ok and type(user) == "table" then
			merge(groups, user, "overrides(fn)", debug)
		end
	elseif type(opts.overrides) == "table" then
		merge(groups, opts.overrides, "overrides(table)", debug)
	end

	return groups
end

--- Apply the highlight groups directly to Neovim.
--- (Called by setup.lua after building the palette.)
---@param S table   Semantic palette
---@param opts table User options
function M.apply(S, opts)
	-- M.get() does a full rebuild across all four group modules. Caching the
	-- result here means :AaltoPreview and reload() don't re-walk every module
	-- on each call with the same palette + opts.
	local groups = M.get(S, opts)
	local count, failed = 0, 0
	for name, spec in pairs(groups) do
		local ok = pcall(vim.api.nvim_set_hl, 0, name, spec)
		if ok then
			count = count + 1
		else
			failed = failed + 1
			if opts and opts.debug then
				vim.notify(string.format("[aalto] Failed to set highlight '%s'", name), vim.log.levels.WARN)
			end
		end
	end
	if opts and opts.debug then
		vim.notify(string.format("[aalto] Applied %d highlight groups (%d failed)", count, failed), vim.log.levels.INFO)
	end
end

return M
