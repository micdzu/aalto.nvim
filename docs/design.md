# Design

This document describes how Aalto is structured internally. It is intended for
contributors and for users who want to understand what is actually happening
when they change a config value.

---

## The pipeline

Every color in Aalto's output is produced by the same pipeline:

```text
base → variants → semantic → link() → groups → highlights
```

Each stage has a single responsibility and does not reach into the ones adjacent
to it. Changes flow in one direction only.

---

## Stage 1: Base (`palette/base.lua`)

The base layer defines **color identity** — the raw hues and tones that
characterize each variant.

```lua
-- Dark variant (abbreviated)
DARK = {
bg = "#18122E",
blue = "#6B7FD4",
green = "#7D8F6E",
magenta = "#B87333",
...
}
```

Dark and light palettes are defined independently. The light palette is not an
inversion of the dark one—inverting a dark palette produces washed‑out results.
Base colors have no semantic meaning yet. `blue` is just blue.

---

## Stage 2: Variants (`palette/variants.lua`)

The variants layer derives UI surface colors from the background using OKLCH
offsets.

```lua
SURFACE_CONFIG = {
  dark = { cursorline = { L_frac = 0.05, chroma_scale = 1.00, } },
  light = { cursorline = { L_frac = 0.03, chroma_scale = 0.30, } },
}
```

Surface colors are derived from the background in OKLCH space by:

- shifting lightness relative to the available range
- scaling chroma to control saturation

---

## Stage 3: Semantic (`palette/semantic.lua`)

The semantic layer is the perceptual core. It takes raw palette colors and
shapes them into a meaningful hierarchy.

### Perceptual weights

Each role has a weight that represents its importance:

```lua
ROLE = {
  definition = { weight = 1.00, chroma = 1.00, base = "blue" },
  constant   = { weight = 0.80, chroma = 0.85, base = "magenta" },
  string     = { weight = 0.60, chroma = 0.70, base = "green" },
  comment    = { weight = 0.40, chroma = 0.50, base = "fg_dark" },
}
```

### Lightness positioning

Instead of adjusting colors to meet contrast targets, we **place** them at a
controlled distance from the background in OKLCH lightness:

```lua
delta = (0.18 + weight * 0.22) * direction
lch.L = bg_lch.L + delta
```

Dark themes push colors lighter; light themes push them darker. The result is a
deterministic, predictable contrast spread.

### Chroma shaping

Chroma is scaled per role to control visual intensity. Definition gets full
saturation; string and comment are progressively desaturated to recede.

### Hierarchy enforcement

After all roles are computed, `utils.enforce_hierarchy()` ensures the perceptual
order `definition > constant > string > comment` holds. It nudges lightness
values if necessary—a safety net, not a primary mechanism.

### Signals

Diagnostic colors (error, warn, info, hint) follow a similar model but with a
slight chroma boost to remain visible in UI contexts.

---

## Stage 4: Link (`groups/link.lua`)

The link layer provides a `link(role, extra)` function that translates role
names into highlight spec tables:

```lua
link("def") → { fg = S.definition }
link("def", { bold = true }) → { fg = S.definition, bold = true }
```

Every group module receives a `link` function bound to the current semantic
palette. Groups never reference `S.definition` directly—they call `link("def")`.
This decouples the palette from the highlight group names.

---

## Stage 5: Groups

Groups are the translation layer between semantic roles and Neovim's highlight
group names. Four modules cover the full editor surface:

| Module                  | Covers                   |
| ----------------------- | ------------------------ |
| `groups/editor.lua`     | Core Neovim groups       |
| `groups/treesitter.lua` | Tree‑sitter `@` captures |
| `groups/lsp.lua`        | LSP semantic tokens      |
| `groups/plugins.lua`    | Third‑party plugins      |

Groups are merged in ascending priority: editor < treesitter < lsp < plugins <
overrides. LSP wins over Treesitter because it has more precise type
information.

---

## The OKLCH color space

Aalto works in OKLCH internally. OKLCH is perceptually uniform—equal steps in
lightness look equal to the eye regardless of hue. HSL fails at this (yellow at
50% lightness looks much brighter than blue at 50%). OKLCH makes contrast
calculations and lightness adjustments reliable.

The pipeline converts to OKLCH at the start of every operation and back to hex
at the end. Caching in `utils.lua` prevents repeated conversions.

---

## Priority order summary

When two modules define the same group, later modules win:

```text
editor → treesitter → lsp → plugins → user overrides
```

User overrides (the `overrides` config key) always win.
