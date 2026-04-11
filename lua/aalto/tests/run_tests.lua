#!/usr/bin/env -S nvim -l
-- Run all Aalto tests.
-- Usage: nvim -l tests/run_tests.lua

-- Add plugin root to runtimepath
vim.cmd("set rtp+=.")
vim.cmd("runtime! plugin/**/*.lua")

local function run_test_file(file)
	local fn = loadfile(file)
	if not fn then
		error("Failed to load " .. file)
	end
	fn()
end

local test_files = {
	"tests/utils_spec.lua",
	-- Add more test files here
}

for _, file in ipairs(test_files) do
	print("\n=== Running " .. file .. " ===")
	run_test_file(file)
end

print("\n✓ All tests completed.")
