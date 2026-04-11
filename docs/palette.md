# Palette

Aalto's palette is not the final output.

> It is the input to a rendering system.

---

## 🧠 Semantic Roles

Aalto reduces color to four roles:

| Role | Meaning |
|------------|----------|
| definition | structure |
| string | data |
| constant | values |
| comment | context |

These roles are stable across:

- languages
- plugins
- UI elements

> Fewer roles → stronger signal.

---

## 🎨 Canonical Palette (Reference)

These values define **color identity**, not final appearance.

They are the starting point for all transformations.

### Dark

| Role | Color | Hex |
|------------|--------|--------|
| Background | Deep indigo | `#18153A` |
| Foreground | Soft lavender | `#C9C2FF` |
| Dimmed | Muted purple | `#746FA3` |
| String | Soft green | `#8FC77C` |
| Constant | Soft magenta | `#B87EDC` |
| Definition | Soft blue | `#7C8CFA` |
| Error | Soft red | `#E87A98` |
| Warning | Soft orange | `#F0A07A` |
| Info | Soft cyan | `#7CD4D1` |

### Light

Light mode is **perceptually derived** from the dark palette. Each color is transformed via OKLCH to maintain hue relationships while meeting contrast targets against a light background (`#E2DFEA`).

You can inspect the derived light palette with `:AaltoVariant light` followed by `:AaltoStatus`.

---

## ⚙️ Rendering Pipeline

Colors are transformed through a fixed pipeline:

```text
base → variants → semantic → perceptual adjustment
```

Each stage has a single responsibility:

- **base** → defines identity (hue + tone)
- **variants** → adapts for environment (light/dark)
- **semantic** → assigns meaning
- **perceptual adjustment** → enforces contrast

This ensures:

- consistent hierarchy
- stable contrast
- preserved identity

---

## 👁 Perceptual System (OKLCH)

Aalto operates in **OKLCH color space**.

This allows:

- adjusting lightness without shifting hue
- preserving semantic identity
- predictable contrast behavior

Unlike RGB-based systems, changes remain perceptually stable.

### Why OKLCH?

| Space | Problem | OKLCH Solution |
|-------|---------|----------------|
| RGB | Lightening changes apparent hue | Perceptually uniform |
| HSL | Blue "max lightness" is still dark | Lightness is absolute |
| LAB | No chroma/hue separation | Intuitive adjustments |

---

## ♿ Adaptive Contrast

```lua
accessibility = {
  enabled = false,
  contrast = 4.5,
}
```

When enabled:

- contrast is adjusted **only when needed**
- original palette relationships are preserved
- no global distortion is introduced

### How It Works

1. Measure current contrast between role and background
2. If below target, adjust lightness in OKLCH space
3. Preserve hue and chroma (color identity)
4. Binary search for optimal lightness

---

## 🎨 Customization

### Override Semantic Roles

```lua
require("aalto").setup({
  palette = {
    definition = "#7C8CFA",  -- Your custom blue
    string = "#8FC77C",      -- Your custom green
    -- etc.
  }
})
```

**Note:** These are semantic overrides, not base palette colors. The variant system (light/dark) still applies to your custom colors.

### Override Base Colors (Advanced)

If you need to change the root identity colors:

```lua
require("aalto").setup({
  palette = {
    bg = "#000000",      -- Override dark background
    fg = "#FFFFFF",      -- Override foreground
    blue = "#0000FF",    -- Override definition source
  }
})
```

When `variant = "light"`, these will be transformed perceptually.

---

## 🧠 Key Idea

The palette is not the goal.

> The mapping between meaning and color is primary.

Color is only a vehicle for structure.

---

## Technical Note: Gamut Clipping

When adjusting colors in OKLCH, some combinations of lightness + chroma fall outside the sRGB gamut. Aalto clamps these values, which can cause slight hue shifts in extreme cases.

For best results, use moderate chroma values (saturation). The default palette is designed to stay well within gamut.
