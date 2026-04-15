# Contributing to Aalto

First: thank you for considering it. Aalto is a small project and every
thoughtful contribution matters.

This document covers everything you need to get started — including the
basics of GitHub if this is your first time contributing to an open source
project.

---

## The core idea (read this first)

Aalto has one guiding principle: **color should express meaning, not decorate
syntax**. Before opening a pull request, ask whether the change serves that
idea. A PR that adds per-language color customization, new token types, or
additional palette hues will almost certainly be declined — not because it's
bad work, but because it works against the design.

Changes that are always welcome:

- Bug fixes
- New plugin highlight group mappings (see [docs/plugins.md](docs/plugins.md))
- Improvements to the OKLCH color engine
- Documentation clarifications
- Test coverage

If you're unsure whether your idea fits, open an issue and ask before writing
any code.

---

## Setting up

You need Neovim 0.9+ and Git. That's it — no Node, no build step, no package
manager.

**Clone the repo:**

```bash
git clone https://github.com/micdzu/aalto.nvim
cd aalto.nvim
```

**Run the tests:**

```bash
nvim --headless -l lua/aalto/tests/run_tests.lua
```

All tests should pass on a clean checkout. If they don't, please open an
issue.

**Try it in Neovim:**

Add the local directory to your plugin manager. With lazy.nvim:

```lua
{ dir = "/path/to/aalto.nvim", priority = 1000 }
```

---

## Project layout

```
colors/          Neovim colorscheme entry point (:colorscheme aalto)
lua/aalto/
  init.lua       Public API and user commands
  setup.lua      Configuration, state, rendering pipeline
  toggle.lua     Runtime utilities (variant switching)
  health.lua     :checkhealth aalto
  statusline.lua Built-in statusline
  palette/
    base.lua     Raw hues for dark and light variants
    variants.lua UI surface colors derived from background
    semantic.lua Perceptual positioning and hierarchy enforcement
    utils.lua    OKLCH color engine (conversions, contrast, gamut)
  groups/
    init.lua     Aggregator — merges all group modules
    editor.lua   Core Neovim highlight groups
    treesitter.lua  Tree-sitter @captures
    lsp.lua      LSP semantic tokens
    plugins.lua  Third-party plugin groups
    link.lua     Role-to-highlight-spec translation
  plugins/
    spec.lua     register_plugin_specs() registry
  tests/
    run_tests.lua   Test runner
    utils_spec.lua  Unit tests for palette/utils.lua
    pipeline_spec.lua  Integration tests for the palette pipeline
docs/
  philosophy.md  Why Aalto exists and what it is trying to do
  design.md      How the pipeline works internally
  palette.md     Palette reference
  customization.md  Configuration guide
  plugins.md     Plugin support and register_plugin_specs() reference
```

The pipeline flows in one direction:

```
base → variants → semantic → link() → groups → highlights
```

Each stage has a single responsibility. Changes should stay within one stage
if at all possible.

---

## Adding plugin support

This is the most common contribution and the most straightforward. Find the
highlight groups your plugin defines (usually in its source or README), map
them to semantic roles, and add them to `lua/aalto/groups/plugins.lua`.

The available roles are `definition`, `constant`, `string`, `comment`, `fg`,
`fg_dark`, `error`, `warn`, `info`, `hint`, `bg`, `bg_light`, `selection`,
`inv_definition`, `inv_constant`, `inv_string`.

Example:

```lua
-- SomePlugin
SomePluginTitle  = link("definition"),
SomePluginBorder = { fg = S.fg_dark, bg = bg_float },
SomePluginError  = link("error"),
```

When in doubt, reach for `definition` for active/selected items, `fg_dark`
for borders and separators, and the signal roles (`error`, `warn`, `info`,
`hint`) for their obvious meanings.

---

## Reporting bugs

Open an issue and include:

1. The output of `:checkhealth aalto`
2. Your `setup()` call
3. What you expected and what you got
4. Neovim version (`nvim --version`)

For visual bugs (wrong color, broken hierarchy), a screenshot helps a lot.

---

## Pull request checklist

Before opening a PR:

- [ ] Tests pass: `nvim --headless -l lua/aalto/tests/run_tests.lua`
- [ ] New behavior has a test if it's in `palette/` or `groups/`
- [ ] Docs updated if you changed the public API or config options
- [ ] Commit messages are plain English describing what changed and why

PRs don't need to be perfect. If you're stuck on something, open the PR as a
draft and ask.

---

## A note on GitHub (if this is your first time)

The basic loop for contributing to any open source project:

1. **Fork** the repo — this creates your own copy on GitHub (button in the
   top right of the repo page)
2. **Clone** your fork locally: `git clone https://github.com/YOUR_NAME/aalto.nvim`
3. **Create a branch** for your change: `git checkout -b fix/my-bug-description`
4. Make your changes and run the tests
5. **Commit**: `git add -A && git commit -m "fix: describe what you changed"`
6. **Push** to your fork: `git push origin fix/my-bug-description`
7. Open a **Pull Request** from your fork's branch to `micdzu/aalto.nvim:main`
   — GitHub will prompt you to do this after you push

If something goes wrong or you're unsure, just open an issue and ask. No
question is too basic.

---

## License

By contributing, you agree that your changes will be licensed under the
project's [MIT License](LICENSE).
