---@module "aalto.ui"
---
--- Semantic UI specification layer for Aalto.
---
--- Maps semantic palette → UI interaction roles.
---
--- This sits BETWEEN:
--- semantic colors → highlight groups
---
--- Philosophy:
--- - Plugins express intent, not color
--- - UI roles are reusable across all plugin integrations
--- - Keeps the visual system consistent and minimal

local M = {}

-- -----------------------------------------------
-- BUILD UI SPEC
-- -----------------------------------------------

---Build a UI role table from the semantic palette.
---
---@param S table Semantic palette
---@param bg string Background (may be "NONE" if transparent)
---@param bg_float string Float background
---@return table ui
function M.build(S, bg, bg_float)
  -- Validate inputs
  if not S or not S.fg or not S.fg_dark then
    vim.notify("[aalto.ui] Invalid semantic palette", vim.log.levels.ERROR)
    return {}
  end

  return {
    -- -----------------------------------------------
    -- SURFACES
    -------------------------------------------------

    base = { fg = S.fg },
    panel = { fg = S.fg, bg = bg_float },
    border = { fg = S.fg_dark, bg = bg_float },
    float = { fg = S.fg, bg = bg_float },

    -- -----------------------------------------------
    -- INTERACTION
    -------------------------------------------------

    selection = { bg = S.selection },
    cursorline = { bg = S.cursorline },
    match = { fg = S.constant },

    -- -----------------------------------------------
    -- HIERARCHY
    -------------------------------------------------

    title = { fg = S.definition },
    accent = { fg = S.definition },
    muted = { fg = S.comment },
    subtle = { fg = S.fg_dark },

    -- -----------------------------------------------
    -- SEMANTIC PASSTHROUGH
    -- Plugin role → semantic role (direct mapping).
    -- Keeps plugin colors tied to semantic meaning.
    -------------------------------------------------

    definition = { fg = S.definition },
    string = { fg = S.string },
    constant = { fg = S.constant },
    comment = { fg = S.comment },

    -- -----------------------------------------------
    -- DIAGNOSTICS
    -------------------------------------------------

    error = { fg = S.error },
    warn = { fg = S.warn },
    info = { fg = S.info },
    hint = { fg = S.hint },
  }
end

return M