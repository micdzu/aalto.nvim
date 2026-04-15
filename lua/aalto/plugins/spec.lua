---@module "aalto.plugins.spec"
---
--- The plugin spec registry. Think of it as a guest list for highlight groups.
--- Built‑in specs are hardcoded; users can add their own via `register_user_specs`.
--- All specs are cleared on reload to prevent duplication (no party crashers).
---
--- Role names match the semantic palette keys: "definition", "constant",
--- "string", "comment", "fg", "fg_dark", "error", "warn", "info", "hint",
--- "bg", "bg_light", "selection", "inv_definition", "inv_constant", "inv_string".

local M = {}

M._user_specs = {}
M._registered_after_setup = false -- tracks whether specs arrived post-setup

function M.register_user_specs(specs)
	if type(specs) ~= "table" then
		return
	end
	for _, spec in ipairs(specs) do
		table.insert(M._user_specs, spec)
	end
	M._registered_after_setup = true
end

function M.clear_user_specs()
	M._user_specs = {}
	M._registered_after_setup = false
end

function M.apply(groups, palette, spec)
	for role, names in pairs(spec) do
		local color = palette[role]
		if color then
			-- Build a minimal highlight spec from the palette value.
			-- Roles that are hex colors become { fg = color }; surface
			-- roles (bg, bg_light, selection) become { bg = color }.
			local SURFACE_ROLES = {
				bg = true,
				bg_light = true,
				bg_float = true,
				selection = true,
				cursorline = true,
			}
			local hl = SURFACE_ROLES[role] and { bg = color } or { fg = color }
			for _, name in ipairs(names) do
				groups[name] = hl
			end
		else
			vim.notify(string.format("[aalto] register_plugin_specs: unknown role '%s'", role), vim.log.levels.WARN)
		end
	end
end

function M.apply_all(groups, palette, builtin_specs)
	for _, spec in ipairs(builtin_specs) do
		M.apply(groups, palette, spec)
	end
	for _, spec in ipairs(M._user_specs) do
		M.apply(groups, palette, spec)
	end
end

return M
