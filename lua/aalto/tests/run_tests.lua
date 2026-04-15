#!/usr/bin/env -S nvim -l
--
-- tests/run_tests.lua
--
-- Run all Aalto unit and integration tests.
--
-- Usage (from the plugin root):
--   nvim -l lua/aalto/tests/run_tests.lua
--
-- The script anchors all paths relative to its own location on disk so
-- it works regardless of the working directory when nvim is invoked.
-- (The previous implementation used bare relative paths, which broke
-- when the script was not run from the plugin root.)

-- -----------------------------------------------
-- ANCHOR TO SCRIPT LOCATION
-- -----------------------------------------------

-- debug.getinfo(1).source returns something like "@/path/to/run_tests.lua"
local script_path = debug.getinfo(1, "S").source:sub(2)  -- strip leading "@"
local script_dir  = vim.fn.fnamemodify(script_path, ":p:h")

-- The plugin root is two levels up: …/lua/aalto/tests/ → …/
local plugin_root = vim.fn.fnamemodify(script_dir .. "/../../..", ":p")

-- Add plugin root to runtimepath so require("aalto.*") resolves correctly
vim.opt.runtimepath:prepend(plugin_root)
vim.cmd("runtime! plugin/**/*.lua")

-- -----------------------------------------------
-- TEST FILE RUNNER
-- -----------------------------------------------

--- Load and execute a test file, reporting success or failure.
---@param file string  absolute path to the test file
---@return boolean ok
---@return string|nil err
local function run_test_file(file)
	local fn, load_err = loadfile(file)
	if not fn then
		return false, "Failed to load: " .. tostring(load_err)
	end
	local ok, run_err = pcall(fn)
	return ok, run_err
end

-- -----------------------------------------------
-- TEST FILES
-- -----------------------------------------------

local test_files = {
	script_dir .. "/utils_spec.lua",
	script_dir .. "/pipeline_spec.lua",
}

-- -----------------------------------------------
-- RUN
-- -----------------------------------------------

local total_ok    = true

for _, file in ipairs(test_files) do
	print("\n=== " .. vim.fn.fnamemodify(file, ":t") .. " ===")
	local ok, err = run_test_file(file)
	if not ok then
		print("FAILED: " .. tostring(err))
		total_ok = false
	end
end

print("")
if total_ok then
	print("✓ All test files passed.")
	os.exit(0)
else
	print("✗ One or more test files failed.")
	os.exit(1)
end
