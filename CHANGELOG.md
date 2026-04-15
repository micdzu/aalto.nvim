# Changelog

All notable changes to Aalto.nvim will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- (Nothing yet – this section is for changes since the last release)

## [1.0.0] - 2026-04-15

### Added

- Initial public release.
- Dark and light variants with perceptual OKLCH color engine.
- Four semantic roles: definition, constant, string, comment.
- Automatic contrast hierarchy and chroma shaping.
- Plugin support for Telescope, fzf-lua, nvim-cmp, blink.cmp, Neo-tree,
  NvimTree, GitSigns, WhichKey, Trouble, nvim-notify, Flash.nvim, Illuminate,
  Indent Blankline, Rainbow Delimiters, todo-comments, Navic, BufferLine, and
  more.
- Extension API (`register_plugin_specs()`) for user‑defined plugin highlights.
- Runtime commands: `:AaltoVariant`, `:AaltoStatus`, `:AaltoReload`,
  `:AaltoPreview`.
- Built‑in minimal statusline (opt‑in).
- Health check via `:checkhealth aalto`.
- Lualine theme integration.
- Live showroom at https://micdzu.github.io/aalto.nvim.
- Comprehensive documentation in `docs/`.

[Unreleased]: https://github.com/micdzu/aalto.nvim/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/micdzu/aalto.nvim/releases/tag/v1.0.0
