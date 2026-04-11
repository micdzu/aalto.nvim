---@module "aalto.plugins.spec"
---
--- Plugin specification → highlight generator.
---
--- Converts declarative plugin specs into highlight groups.
---
--- Philosophy:
--- - Plugins define roles (panel, match, title)
--- - This module maps roles → actual highlight specs
--- - Unknown roles fail safely (no crash)

local M = {}

-------------------------------------------------
-- APPLY SINGLE SPEC
-------------------------------------------------

---@param groups table<string, table>
---@param ui table
---@param spec table<string, string[]>
function M.apply(groups, ui, spec)
	for role, names in pairs(spec) do
		local hl = ui[role]

		-- Skip unknown roles (safe behavior)
		if hl then
			for _, name in ipairs(names) do
				groups[name] = hl
			end
		end
	end
end

-------------------------------------------------
-- APPLY MULTIPLE SPECS
-------------------------------------------------

---@param groups table
---@param ui table
---@param specs table[]
function M.apply_all(groups, ui, specs)
	for _, spec in ipairs(specs) do
		M.apply(groups, ui, spec)
	end
end

return M
