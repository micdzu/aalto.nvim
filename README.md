# Aalto.nvim

<p align="center">
  <a href="https://micdzu.github.io/aalto.nvim/">
    <img src="https://img.shields.io/badge/🎨_Visit_the_Showroom-Live_Demo-6B7FD4?style=for-the-badge&labelColor=18122E" alt="Aalto Showroom">
  </a>
</p>

> Color that means something. Everything else fades away.

![Aalto screenshot](assets/preview.png)

Most colorschemes are hex tables with opinions. Aalto is a perceptual color
engine that happens to produce a colorscheme.

The difference in practice: when you change a color in Aalto, you change a _hue
identity_. Contrast, saturation, and the visual hierarchy between roles are
recomputed automatically in [OKLCH](https://oklch.com) space — a perceptually
uniform color model where equal numeric steps look equal to the eye. You get a
coherent result without manually tweaking six related values.

---

## The idea

Aalto maps all of code down to four semantic roles and colors those. Everything
else — keywords, operators, punctuation, variables — renders in neutral
foreground.

| Role         | Meaning   | Examples                           |
| ------------ | --------- | ---------------------------------- |
| `definition` | Structure | functions, types, classes, modules |
| `constant`   | Values    | numbers, booleans, enum members    |
| `string`     | Data      | string literals                    |
| `comment`    | Context   | comments, documentation            |

The hierarchy `definition > constant > string > comment` is enforced
perceptually, not just numerically — each role is placed at a deliberate
distance from the background in OKLCH lightness, so the prominence ordering
holds across both dark and light variants regardless of hue.

The result is an editor that quietly shows you the shape of your code. The best
colorscheme is the one you stop noticing.

Read the full reasoning in [docs/philosophy.md](docs/philosophy.md).

---

## Features

- **Semantic-first** — four roles, consistent across every language
- **OKLCH color engine** — perceptually uniform; adjustments look right
- **Automatic contrast hierarchy** — definition > constant > string > comment
- **Dual palettes** — independent dark and light variants, hand-tuned
- **Deep plugin coverage** — Telescope, nvim-cmp, Neo-tree, Gitsigns, Which-key,
  Trouble, Notify, and more
- **Extension API** — add highlight mappings for your own plugins without
  modifying core files
- **Runtime commands** — switch variants, preview, reload without restarting
- **Built-in statusline** — minimal, semantic, opt-in
- **Health check** — `:checkhealth aalto` reports contrast, gamut, and
  light/dark balance

---

## Requirements

- Neovim 0.9+
- 24-bit color terminal or GUI

---

## Installation

**lazy.nvim**

```lua
{
  "micdzu/aalto.nvim",
  priority = 1000,
  config = function()
    require("aalto").setup({})
    vim.cmd("colorscheme aalto")
  end,
}
```

**packer.nvim**

```lua
use {
  "micdzu/aalto.nvim",
  config = function()
    require("aalto").setup({})
    vim.cmd("colorscheme aalto")
  end,
}
```

**vim-plug**

```vim
Plug 'micdzu/aalto.nvim'
```

```lua
require("aalto").setup({})
vim.cmd("colorscheme aalto")
```

---

## Quick start

```lua
-- Dark variant, all defaults
require("aalto").setup({})
vim.cmd("colorscheme aalto")
```

```lua
-- Light variant
require("aalto").setup({ variant = "light" })
vim.cmd("colorscheme aalto")
```

---

## Configuration

```lua
require("aalto").setup({
  -- "dark" or "light"
  variant = "dark",

  -- Override raw palette hues. Contrast and hierarchy are re-applied on top.
  palette = {
    definition = "#7C8CFA",
    string     = "#8FC77C",
    constant   = "#B87EDC",
    comment    = "#746FA3",
  },

  -- Override semantic role colors directly, bypassing palette mapping.
  semantic = {
    definition = "#82AAFF",
  },

  -- Bold/italic for comments and keywords only.
  styles = {
    comments = { italic = true },
    keywords = {},             -- e.g. { bold = true }
  },

  -- Transparent backgrounds.
  transparent       = false,  -- main windows
  float_transparent = false,  -- floating windows

  -- Set terminal_color_0 … terminal_color_15.
  terminal_colors = true,

  -- Applied last, wins over everything.
  overrides = {
    -- ["@keyword"] = { italic = true },
  },

  -- Enable built-in statusline.
  statusline = false,

  -- Print resolved palette after setup.
  debug = false,
})
```

Full customization reference: [docs/customization.md](docs/customization.md)

---

## Commands

| Command                       | Description                                   |
| ----------------------------- | --------------------------------------------- |
| `:AaltoVariant [dark\|light]` | Switch variant, or toggle if no argument      |
| `:AaltoStatus`                | Show current configuration                    |
| `:AaltoReload`                | Re-apply highlights with the last used config |
| `:AaltoPreview dark\|light`   | Preview a variant temporarily without saving  |

---

## Lualine

```lua
require("lualine").setup({
  options = {
    theme = require("aalto").lualine_theme(),
  },
})
```

Pass `{ lualine_style = "full" }` for a filled mode indicator instead of the
default minimal one.

---

## Custom plugin highlights

```lua
require("aalto").register_plugin_specs({
  {
    definition = { "MyPluginTitle", "MyPluginHeader" },
    fg_dark    = { "MyPluginBorder", "MyPluginSeparator" },
    error      = { "MyPluginErrorSign" },
    string     = { "MyPluginAddedLine" },
  },
})
```

Available roles: `definition`, `constant`, `string`, `comment`, `fg`, `fg_dark`,
`error`, `warn`, `info`, `hint`, `bg`, `bg_light`, `selection`,
`inv_definition`, `inv_constant`, `inv_string`.

Full reference: [docs/plugins.md](docs/plugins.md)

---

## Health check

```vim
:checkhealth aalto
```

Reports contrast ratios, gamut warnings, and a light/dark comparison table.

---

## Architecture

```
base → variants → semantic → link() → groups → highlights
```

- **base** — raw hues (dark/light palettes)
- **variants** — UI surfaces derived from background in OKLCH
- **semantic** — lightness positioning, chroma shaping, hierarchy enforcement
- **link()** — role-to-highlight-spec translation
- **groups** — Neovim highlight group definitions

Full internals: [docs/design.md](docs/design.md)

---

## License

MIT
