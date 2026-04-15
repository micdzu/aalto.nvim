# Plugin Support

Aalto does not theme plugins individually. Instead, plugins inherit from the
same semantic role system that governs the editor itself—the same `link()`
function, the same palette, the same hierarchy.

---

## How it works

Every plugin highlight group is mapped to a semantic role:

```lua
-- from groups/plugins.lua
g.TelescopeTitle    = link("definition")   -- titles use definition color
g.TelescopeMatching = link("definition")   -- matches use definition color
g.GitSignsAdd       = link("string")       -- additions use string color
g.GitSignsChange    = link("constant")     -- changes use constant color
g.GitSignsDelete    = link("error")        -- deletions use error color
```

When you change a palette color, every plugin that uses that role updates
automatically. No per‑plugin configuration required.

---

## Supported plugins

### Fuzzy finding

- **Telescope** — normal, border, title, selection, matching
- **fzf‑lua** — normal, border, title, cursorline, search

### Completion

- **nvim‑cmp** — abbreviation, match, kind, menu
- **blink.cmp** — full kind coverage

### File tree

- **Neo‑tree** — directories, files, git status
- **NvimTree** — (partial coverage, enough to look decent)

### Git

- **Gitsigns** — add, change, delete signs and line highlights

### Navigation

- **Which‑key** — key, group, description, separator
- **Navic** — breadcrumbs

### Diagnostics

- **Trouble** — all severity levels
- **nvim‑notify** — error, warn, info, hint, debug, trace

### Search

- **Flash.nvim** — match, current, label

### UI

- **BufferLine** — fill, background, selected buffer, indicators
- **Indent Blankline** — indent character, scope character
- **Rainbow Delimiters** — all six levels

### Highlighting

- **Illuminate** — word references

### Comments

- **todo‑comments** — TODO, FIX, WARN, INFO, HINT

---

## Adding support for your own plugins

Use `register_plugin_specs()` to add highlight mappings without modifying
Aalto's source:

```lua
require("aalto").register_plugin_specs({
  {
    definition = { "MyPluginTitle", "MyPluginHeader" },
    fg_dark    = { "MyPluginBorder", "MyPluginSeparator" },
    fg         = { "MyPluginNormal" },
    error      = { "MyPluginErrorSign" },
    string     = { "MyPluginAddedLine" },
  },
})
```

Each key is a role name; each value is a list of highlight group names. The
mapping is applied after all built‑in specs, so it can override defaults.

### Available roles

| Role          | Color               | Typical use                             |
| ------------- | ------------------- | --------------------------------------- |
| `definition`  | definition          | titles, matches, active items           |
| `constant`    | constant            | changed items, counts, secondary accent |
| `string`      | string              | added items, success states             |
| `comment`     | comment             | documentation, secondary text           |
| `fg`          | foreground          | normal text                             |
| `fg_dark`     | muted foreground    | borders, separators, dim text           |
| `error`       | error               | errors, deleted items                   |
| `warn`        | warning             | warnings, modified items                |
| `info`        | info                | informational items                     |
| `hint`        | hint                | hints, suggestions                      |
| `bg`          | background          | panel backgrounds                       |
| `bg_light`    | raised background   | floating window backgrounds             |
| `selection`   | selection           | selected items, references              |
| `inv_definition` | inverted definition | search highlights, flash current     |
| `inv_constant`   | inverted constant   | secondary search highlights          |
| `inv_string`     | inverted string     | substitute highlights                |

### Specs with extra attributes

For groups that need a role plus additional attributes (like `bold`), use the
`overrides` key in `setup()`:

```lua
overrides = {
  MyPluginBoldTitle = { fg = require("aalto").get_palette().definition, bold = true },
}
```

---

## Statusline groups

Aalto exposes semantic statusline highlight groups for custom statuslines:

| Group            | Meaning           |
| ---------------- | ----------------- |
| `AaltoSLFg`      | Normal text       |
| `AaltoSLDim`     | Dimmed text       |
| `AaltoSLNormal`  | Normal mode       |
| `AaltoSLInsert`  | Insert mode       |
| `AaltoSLVisual`  | Visual mode       |
| `AaltoSLReplace` | Replace mode      |
| `AaltoSLCommand` | Command mode      |
| `AaltoSLError`   | Error count       |
| `AaltoSLWarn`    | Warning count     |
| `AaltoSLStr`     | Git added lines   |
| `AaltoSLConst`   | Git changed lines |
| `AaltoSLComment` | Git branch        |

These groups are always defined, regardless of `statusline = true`.
