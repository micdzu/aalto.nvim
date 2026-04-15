# Customization

Aalto is customized through a layered system. Each layer handles a different
kind of change, and using the right layer gives cleaner results with fewer
surprises.

```text
palette → semantic → styles → overrides
```

---

## Choosing the right layer

| I want to…                                                | Use                       |
| --------------------------------------------------------- | ------------------------- |
| Change the color character (different blue, warmer green) | `palette`                 |
| Change exactly what a role looks like                     | `semantic`                |
| Add or remove italic on comments                          | `styles.comments`         |
| Add or remove bold/italic on keywords                     | `styles.keywords`         |
| Adjust one specific highlight group                       | `overrides`               |
| Register highlights for my own plugin                     | `register_plugin_specs()` |

---

## Layer 1: Palette

The `palette` key changes the raw hues that feed into the semantic pipeline.
Contrast and hierarchy are still enforced—you're just shifting the color
identity.

```lua
require("aalto").setup({
  palette = {
    -- Use role names (preferred)
    definition = "#82AAFF",   -- warmer blue
    string     = "#C3E88D",   -- brighter green
    constant   = "#C792EA",   -- different purple

    -- Or use base palette keys
    blue    = "#82AAFF",
    green   = "#C3E88D",
    magenta = "#C792EA",

    -- You can also change the background
    -- bg = "#1A1B26",
  },
})
```

---

## Layer 2: Semantic

The `semantic` key sets the final value of a role directly, bypassing the
base‑palette mapping. The color still receives chroma shaping and hierarchy
enforcement.

```lua
require("aalto").setup({
  semantic = {
    definition = "#82AAFF",
    comment    = "#637777",
  },
})
```

Use `semantic` when you know exactly what you want and `palette` feels too
indirect.

---

## Layer 3: Styles

The `styles` key controls **only** comments and keywords formatting.

```lua
require("aalto").setup({
  styles = {
    comments = { italic = true },   -- default
    keywords = {},                  -- no formatting (default)
  },
})
```

To make keywords italic:

```lua
styles = {
  keywords = { italic = true },
}
```

No other roles accept styling—by design. If you want more control, use
`overrides`.

---

## Layer 4: Overrides

The `overrides` key accepts raw highlight group specs that are applied last.
They win over everything.

```lua
require("aalto").setup({
  overrides = {
    ["@keyword"] = { italic = true, fg = "#C9C2FF" },
    Normal       = { bg = "#1A1B26" },
  },
})
```

Use overrides sparingly. If you find yourself writing many, consider whether a
`palette` or `semantic` change would be cleaner.

---

## Transparency

```lua
require("aalto").setup({
  transparent       = true,  -- main background
  float_transparent = true,  -- floating windows
})
```

---

## Terminal colors

Aalto sets `terminal_color_0` through `terminal_color_15` by default. Disable if
your terminal manages its own palette:

```lua
require("aalto").setup({
  terminal_colors = false,
})
```

---

## Custom plugin highlights

```lua
require("aalto").register_plugin_specs({
  {
    definition = { "MyPluginTitle", "MyPluginHeader" },
    fg_dark    = { "MyPluginBorder", "MyPluginDim" },
    string     = { "MyPluginValue" },
    error      = { "MyPluginError" },
  },
})
```

Available roles: `definition`, `constant`, `string`, `comment`, `fg`, `fg_dark`,
`error`, `warn`, `info`, `hint`, `bg`, `bg_light`, `selection`,
`inv_definition`, `inv_constant`, `inv_string`.

Call `register_plugin_specs()` before `setup()` or reload afterwards.

---

## Complete example

```lua
require("aalto").setup({
  variant = "dark",

  palette = {
    blue = "#82AAFF",
  },

  styles = {
    comments = { italic = true },
    keywords = {},
  },

  transparent = true,

  overrides = {
    WinSeparator = { fg = "#3B3F5C" },
  },
})
```
