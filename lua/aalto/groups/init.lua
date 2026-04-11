---@module "aalto.groups"
---
--- Highlight group aggregator for Aalto.
---
--- Responsibilities:
--- - Load highlight groups from sub-modules
--- - Resolve transparency backgrounds once (shared across all modules)
--- - Apply user overrides last (highest priority)
--- - Expose M.get() (returns table) and M.apply() (writes to Neovim)
---
--- Sub-module API (unified):
--- All group modules receive the same argument signature:
---
---   mod.get(S, bg, bg_float, opts)
---
--- where:
---   S         → semantic palette
---   bg        → resolved main background (may be "NONE" if transparent)
---   bg_float  → resolved float background (may be "NONE" if float_transparent)
---   opts      → full options table (includes opts.styles, opts.strict, etc.)
---
--- This unified signature means all modules have consistent access to
--- transparency-resolved backgrounds and full options without any module
--- needing to re-resolve transparency logic itself.
---
--- ---------------------------------------------------------
--- BUG FIX (vs original)
--- ---------------------------------------------------------
---
--- The `styles` local variable was extracted from `opts` but then
--- inconsistently forwarded:
---
---   local styles = opts.styles or {}            -- extracted
---   load("aalto.groups.editor",     ..., opts)  -- receives opts (has styles inside)
---   load("aalto.groups.treesitter", ..., opts)  -- receives opts (has styles inside)
---   load("aalto.groups.lsp",        ..., opts)  -- receives opts (has styles inside)
---   load("aalto.groups.plugins",    ..., styles) -- receives raw styles only (!)
---
--- The asymmetry meant plugins.get() received a flat styles table, while
--- the other modules received the full opts table. This was either a bug
--- (plugins was missing context) or dead code (local styles was never needed).
---
--- FIX: All modules now receive `opts` consistently. The `local styles`
--- variable is removed. Each module accesses opts.styles as needed.

local M = {}

-- -----------------------------------------------
-- INTERNAL HELPERS
-- -----------------------------------------------

---Safely require a module and call its `get` function.
---
---On any failure (require error, missing get(), runtime error in get(),
---or non-table return), returns an empty table and optionally warns.
---
---@param name string Lua module path
---@param opts table|nil Used for debug flag only
---@param ... any Arguments forwarded to mod.get()
---@return table groups (empty on failure)
local function load(name, opts, ...)
	local ok, mod = pcall(require, name)

	if not ok then
		if opts and opts.debug then
			vim.notify(
				string.format("[aalto] failed to require '%s': %s", name, tostring(mod)),
				vim.log.levels.WARN
			)
		end
		return {}
	end

	if type(mod.get) ~= "function" then
		if opts and opts.debug then
			vim.notify(
				string.format("[aalto] module '%s' has no get() function", name),
				vim.log.levels.WARN
			)
		end
		return {}
	end

	local ok2, result = pcall(mod.get, ...)
	if not ok2 then
		if opts and opts.debug then
			vim.notify(
				string.format("[aalto] error in '%s'.get(): %s", name, tostring(result)),
				vim.log.levels.WARN
			)
		end
		return {}
	end

	if type(result) ~= "table" then
		return {}
	end

	return result
end

---Merge two highlight group tables (new wins on conflict).
---@param base table Existing groups
---@param new table Incoming groups
---@return table Merged result
local function merge(base, new)
	return vim.tbl_deep_extend("force", base, new)
end

-- -----------------------------------------------
-- PUBLIC
-- -----------------------------------------------

---Build and return all highlight groups for the current configuration.
---
---@param S table Semantic palette
---@param opts table User options (styles, strict, transparent, overrides, etc.)
---@return table groups All highlight group definitions
function M.get(S, opts)
	opts = opts or {}
	local groups = {}

	-- -----------------------------------------------
	-- BACKGROUND RESOLUTION (SHARED ACROSS ALL MODULES)
	-- Transparency is resolved once here so sub-modules
	-- don't need to re-implement the same logic.
	-------------------------------------------------

	local bg = opts.transparent and "NONE" or S.bg

	local bg_float
	if opts.transparent and opts.float_transparent then
		bg_float = "NONE"
	else
		bg_float = S.bg_light
	end

	-- -----------------------------------------------
	-- CORE MODULES
	-- Unified API: all modules receive (S, bg, bg_float, opts).
	-- opts contains opts.styles, opts.strict, etc.
	-------------------------------------------------

	groups = merge(groups, load("aalto.groups.editor",     opts, S, bg, bg_float, opts))
	groups = merge(groups, load("aalto.groups.treesitter", opts, S, bg, bg_float, opts))
	groups = merge(groups, load("aalto.groups.lsp",        opts, S, bg, bg_float, opts))

	-- -----------------------------------------------
	-- PLUGIN MODULES
	-- FIX: plugins now receives `opts` (not a bare `styles` table)
	-- to match the same API contract as editor/treesitter/lsp.
	-- All modules access opts.styles internally if needed.
	-------------------------------------------------

	groups = merge(groups, load("aalto.groups.plugins", opts, S, bg, bg_float, opts))

	-- -----------------------------------------------
	-- USER OVERRIDES (HIGHEST PRIORITY)
	-- Applied last — always wins over everything above.
	-------------------------------------------------

	if opts.overrides
		and type(opts.overrides) == "table"
		and not vim.tbl_isempty(opts.overrides)
	then
		groups = merge(groups, opts.overrides)
	end

	return groups
end

---Apply highlight groups to Neovim.
---
---Iterates the resolved group table and calls nvim_set_hl for each entry.
---Failures are silently skipped (with an optional debug warning) so that
---a single malformed group does not abort the entire colorscheme load.
---
---@param S table Semantic palette
---@param opts table User options
function M.apply(S, opts)
	local groups = M.get(S, opts)

	local count = 0
	for name, spec in pairs(groups) do
		local ok = pcall(vim.api.nvim_set_hl, 0, name, spec)
		if ok then
			count = count + 1
		elseif opts and opts.debug then
			vim.notify(
				string.format("[aalto] Failed to set highlight '%s'", name),
				vim.log.levels.WARN
			)
		end
	end

	if opts and opts.debug then
		vim.notify(
			string.format("[aalto] Applied %d highlight groups", count),
			vim.log.levels.INFO
		)
	end
end

return M
