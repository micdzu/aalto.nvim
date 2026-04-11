---@module "aalto.toggle"
---
--- Runtime toggle utilities for Aalto.
---
--- Provides:
--- M.toggle_accessibility() — toggle adaptive contrast on/off
--- M.toggle_variant() — switch between dark/light modes
--- M.status() — print current configuration

local M = {}

-- -----------------------------------------------
-- TOGGLE ACCESSIBILITY
-- -----------------------------------------------

---Toggle the adaptive contrast system.
---
---Re-runs the full setup pipeline with
---accessibility.enabled flipped.
function M.toggle_accessibility()
  local setup = require("aalto.setup")

  local cfg = setup.get_config()
  if not cfg or not next(cfg) then
    vim.notify(
      "[aalto] not initialized — call require('aalto').setup() first",
      vim.log.levels.ERROR
    )
    return
  end

  local next_cfg = vim.tbl_deep_extend("force", {}, cfg, {
    accessibility = vim.tbl_deep_extend("force", {}, cfg.accessibility or {}, {
      enabled = not (cfg.accessibility and cfg.accessibility.enabled),
    }),
  })

  local ok, err = setup.setup(next_cfg)
  if not ok then
    vim.notify("[aalto] Failed to toggle accessibility: " .. (err or "unknown"), vim.log.levels.ERROR)
    return
  end

  vim.notify(
    "[aalto] accessibility → "
    .. (next_cfg.accessibility.enabled and "ON" or "OFF"),
    vim.log.levels.INFO
  )
end

-- -----------------------------------------------
-- TOGGLE VARIANT
-- -----------------------------------------------

---Toggle between dark and light variants.
---
---Cycles: dark → light → dark
function M.toggle_variant()
  local setup = require("aalto.setup")

  local cfg = setup.get_config()
  if not cfg or not next(cfg) then
    vim.notify(
      "[aalto] not initialized — call require('aalto').setup() first",
      vim.log.levels.ERROR
    )
    return
  end

  local current = cfg.variant or "dark"
  local next_variant = current == "dark" and "light" or "dark"

  local next_cfg = vim.tbl_deep_extend("force", {}, cfg, {
    variant = next_variant,
  })

  local ok, err = setup.setup(next_cfg)
  if not ok then
    vim.notify("[aalto] Failed to switch variant: " .. (err or "unknown"), vim.log.levels.ERROR)
    return
  end

  vim.notify("[aalto] variant → " .. next_variant, vim.log.levels.INFO)
end

-- -----------------------------------------------
-- STATUS
-- -----------------------------------------------

---Print the current Aalto configuration.
function M.status()
  local setup = require("aalto.setup")

  local cfg = setup.get_config()
  if not cfg or not next(cfg) then
    vim.notify(
      "[aalto] not initialized — call require('aalto').setup() first",
      vim.log.levels.WARN
    )
    return
  end

  local lines = {
    "Aalto status:",
    " variant → " .. tostring(cfg.variant or "dark"),
    " accessibility → " .. tostring(cfg.accessibility and cfg.accessibility.enabled or false),
    " strict mode → " .. tostring(cfg.strict),
    " debug mode → " .. tostring(cfg.debug),
    " transparent → " .. tostring(cfg.transparent),
  }

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

return M