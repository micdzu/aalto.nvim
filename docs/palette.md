# Palette

The palette defines the raw color identity of each variant — the hues and
materials that everything else is built from.

These are **base colors**, not final highlight colors. The semantic layer
reshapes them perceptually depending on context.

---
## 🌑 Dark

| Role             | Color                                                                        |
| ---------------- | ---------------------------------------------------------------------------- |
| bg               | ![](https://img.shields.io/badge/-18122E-18122E?style=flat-square) `#18122E` |
| fg               | ![](https://img.shields.io/badge/-EAE1D8-EAE1D8?style=flat-square) `#EAE1D8` |
| fg_dark          | ![](https://img.shields.io/badge/-706873-706873?style=flat-square) `#706873` |
| fg_light         | ![](https://img.shields.io/badge/-F5F0E6-F5F0E6?style=flat-square) `#F5F0E6` |
| blue             | ![](https://img.shields.io/badge/-6B7FD4-6B7FD4?style=flat-square) `#6B7FD4` |
| magenta (copper) | ![](https://img.shields.io/badge/-B87333-B87333?style=flat-square) `#B87333` |
| accent_magenta   | ![](https://img.shields.io/badge/-A06AA8-A06AA8?style=flat-square) `#A06AA8` |
| green            | ![](https://img.shields.io/badge/-7D8F6E-7D8F6E?style=flat-square) `#7D8F6E` |
| red              | ![](https://img.shields.io/badge/-C46B6B-C46B6B?style=flat-square) `#C46B6B` |
| orange           | ![](https://img.shields.io/badge/-D4A373-D4A373?style=flat-square) `#D4A373` |
| cyan             | ![](https://img.shields.io/badge/-6B9A92-6B9A92?style=flat-square) `#6B9A92` |
---

## 🌕 Light

| Role             | Color                                                                        |
| ---------------- | ---------------------------------------------------------------------------- |
| bg               | ![](https://img.shields.io/badge/-F2EDE6-F2EDE6?style=flat-square) `#F2EDE6` |
| fg               | ![](https://img.shields.io/badge/-2B2740-2B2740?style=flat-square) `#2B2740` |
| fg_dark          | ![](https://img.shields.io/badge/-9A948C-9A948C?style=flat-square) `#9A948C` |
| fg_light         | ![](https://img.shields.io/badge/-4A4656-4A4656?style=flat-square) `#4A4656` |
| blue             | ![](https://img.shields.io/badge/-5C63C0-5C63C0?style=flat-square) `#5C63C0` |
| magenta (copper) | ![](https://img.shields.io/badge/-8A5A3C-8A5A3C?style=flat-square) `#8A5A3C` |
| accent_magenta   | ![](https://img.shields.io/badge/-8A5A90-8A5A90?style=flat-square) `#8A5A90` |
| green            | ![](https://img.shields.io/badge/-61784F-61784F?style=flat-square) `#61784F` |
| red              | ![](https://img.shields.io/badge/-9C4A4A-9C4A4A?style=flat-square) `#9C4A4A` |
| orange           | ![](https://img.shields.io/badge/-8A6B4A-8A6B4A?style=flat-square) `#8A6B4A` |
| cyan             | ![](https://img.shields.io/badge/-4F7A70-4F7A70?style=flat-square) `#4F7A70` |

---

## Role mapping

| Semantic role | Base key |
| ------------- | -------- |
| definition    | blue     |
| constant      | magenta  |
| string        | green    |
| comment       | fg_dark  |
| error         | red      |
| warn          | orange   |
| info          | cyan     |
| hint          | cyan     |

---

## Accent magenta

`accent_magenta` exists for **ecosystem compatibility**, not aesthetics.

Some plugins and syntax groups expect a traditional magenta/purple. This color
is provided for those cases but is not used in the core semantic mapping.

It is intentionally subdued and should be used sparingly.

---

## Surfaces (derived)

These colors are generated automatically:

- `bg_light`
- `selection`
- `cursorline`
- `bg_float`

They are derived from `bg` using perceptual transformations (OKLCH), including
subtle hue inheritance.

---

## Notes

- Colors are chosen as **materials**, not abstract hues: birch, copper, moss,
  terracotta.
- The palette is intentionally **low-chroma and cohesive**.
- Final appearance depends on the semantic pipeline.

The palette is the input. What you see is the system.
