---@module "aalto.statusline"
---
--- A statusline that understands semantic roles.
--- It's minimal, readable, and doesn't try to be a dashboard.
--- Enable with `statusline = true` in your Aalto config.

local M = {}

local function hl(group, text)
	return "%#" .. group .. "#" .. text .. "%*"
end

local function is_active()
	return vim.g.statusline_winid == vim.api.nvim_get_current_win()
end

local function hl_dyn(group, text)
	if not is_active() then
		group = "AaltoSLDim"
	end
	return hl(group, text)
end

local function is_medium()
	return vim.o.columns > 80
end

-- Mode mapping
local function mode_group()
	local m = vim.fn.mode()
	if m:match("i") then
		return "AaltoSLInsert"
	end
	if m:match("[vV\22]") then
		return "AaltoSLVisual"
	end
	if m:match("R") then
		return "AaltoSLReplace"
	end
	if m:match("c") then
		return "AaltoSLCommand"
	end
	return "AaltoSLNormal"
end

local function mode_icon()
	local m = vim.fn.mode()
	if m:match("i") then
		return "●"
	end
	if m:match("[vV\22]") then
		return "◆"
	end
	if m:match("R") then
		return "■"
	end
	if m:match("c") then
		return "▶"
	end
	return "●"
end

local function filename()
	local name = vim.fn.expand("%:~:.")
	if name == "" then
		return "[No Name]"
	end
	if #name > 40 then
		return "…" .. name:sub(-37)
	end
	return name
end

local function git_branch()
	local g = vim.b.gitsigns_head
	return (g and g ~= "") and hl_dyn("AaltoSLComment", " " .. g) or ""
end

local function git_diff()
	local g = vim.b.gitsigns_status_dict
	if not g or vim.tbl_isempty(g) then
		return ""
	end
	local parts = {}
	if g.added and g.added > 0 then
		parts[#parts + 1] = hl_dyn("AaltoSLStr", "+" .. g.added)
	end
	if g.changed and g.changed > 0 then
		parts[#parts + 1] = hl_dyn("AaltoSLConst", "~" .. g.changed)
	end
	if g.removed and g.removed > 0 then
		parts[#parts + 1] = hl_dyn("AaltoSLError", "-" .. g.removed)
	end
	return table.concat(parts, " ")
end

local function diagnostics()
	local e = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
	local w = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
	if e == 0 and w == 0 then
		return ""
	end
	if e > 0 then
		return hl_dyn("AaltoSLError", " " .. e)
	end
	return hl_dyn("AaltoSLWarn", " " .. w)
end

local function lsp()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 or not is_medium() then
		return ""
	end
	local names = {}
	for _, c in ipairs(clients) do
		table.insert(names, c.name)
	end
	return hl_dyn("AaltoSLDim", table.concat(names, ","))
end

local function fileinfo()
	local ft = vim.bo.filetype
	if ft == "" then
		ft = "plain"
	end
	return hl_dyn("AaltoSLDim", ft .. " " .. vim.bo.fileformat)
end

local function position()
	return hl_dyn("AaltoSLFg", string.format("%d:%d", vim.fn.line("."), vim.fn.col(".")))
end

function M.render()
	local left, right = {}, {}
	table.insert(left, hl_dyn(mode_group(), mode_icon()))
	table.insert(left, hl_dyn("AaltoSLFg", filename()))

	local branch = git_branch()
	if branch ~= "" and is_medium() then
		table.insert(left, hl_dyn("AaltoSLDim", "│"))
		table.insert(left, branch)
	end

	local diag = diagnostics()
	local diff = git_diff()
	if diag ~= "" then
		table.insert(left, diag)
	elseif diff ~= "" and is_medium() then
		table.insert(left, diff)
	end

	local lsp_name = lsp()
	if lsp_name ~= "" then
		table.insert(left, lsp_name)
	end

	table.insert(right, fileinfo())
	table.insert(right, position())

	return table.concat(left, " ") .. "%=" .. table.concat(right, " ")
end

return M
