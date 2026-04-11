# Plugins

Plugins are not themed independently.

They are rendered through the same semantic system as code.

---

## 🧠 Philosophy

Plugins should feel native.

They should not introduce new colors.

All visual elements are derived from the same semantic roles.

---

## 🧩 Mapping

UI elements are mapped to semantic roles:

| UI Element | Semantic Role | Rationale |
|------------|---------------|-----------|
| Structure (headers, directories) | definition | Navigation anchors |
| Data (filenames, content) | string | Information display |
| Highlights (matches, selections) | constant | Temporary signals |
| Metadata (line numbers, hints) | comment | Secondary context |

This mapping is consistent across:

- plugins
- UI components
- editor elements

---

## ⚙️ System Design

Plugin styling is not hardcoded.

It is a projection of semantic roles onto UI elements via `aalto.ui.build()`.

This ensures:

- consistency across the editor
- reduced cognitive load
- predictable visual behavior

### How It Works

1. Plugin defines UI roles: `panel`, `border`, `selection`, `match`, etc.
2. `ui.build()` maps these to semantic colors
3. `spec.apply_all()` generates highlight groups
4. Final result respects transparency and accessibility settings

---

## 🔒 Constraint

If a plugin requires new colors to look correct,
it is likely breaking the semantic model.

Aalto does not adapt to plugins.
Plugins adapt to the system.

**Example:** If a plugin wants a "special purple" for its unique feature, it should use either:
- `definition` (if it's structural)
- `constant` (if it's a value/signal)
- `string` (if it's data)
- `comment` (if it's metadata)

Not a custom hex code.

---

## 🎯 Supported Plugins

Aalto provides first-class support for:

### Fuzzy Finders
- **Telescope** — `TelescopeNormal`, `TelescopeBorder`, `TelescopeSelection`, `TelescopeMatching`
- **FZF-Lua** — `FzfLuaNormal`, `FzfLuaBorder`, `FzfLuaSearch`, `FzfLuaCursorLine`

### Completion
- **nvim-cmp** — All `CmpItemKind*` groups mapped to semantic roles
- **blink.cmp** — All `BlinkCmpKind*` groups mapped to semantic roles

### Git
- **Gitsigns** — Add/change/delete hunks mapped to `string`/`constant`/`error`

### File Tree
- **Neo-tree** — Directories (`definition`), files (`string`), git status (semantic colors)

### Keybindings
- **Which-key** — Keys (`definition`), descriptions (`muted`/comment)

---

## 🔧 Customizing Plugin Highlights

If you need to override a specific plugin highlight:

```lua
require("aalto").setup({
  overrides = {
    -- Override Telescope selection
    TelescopeSelection = { bg = "#FF0000", bold = true },

    -- Custom plugin not in supported list
    MyPluginHighlight = { fg = "#7C8CFA" },  -- Use definition color
  }
})
```

---

## 🚀 Requesting Support

To request support for a new plugin:

1. Identify which UI roles it uses (panel, border, selection, match, title, muted)
2. Check if these map to existing semantic concepts
3. File an issue with the plugin name and highlight groups it defines

Aalto only adds plugins that fit the semantic model. Plugins requiring arbitrary colors will not be added (use `overrides` instead).

---

## 🎯 Goal

Plugins should not look themed.

They should look like part of the editor.
