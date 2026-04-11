# Design

Aalto is not a theme.

It is a constrained system for rendering meaning.

---

## 🧠 Principles

Aalto is built on three constraints:

- **color is limited**
- **meaning is primary**
- **perception is the goal**

These constraints guide every decision.

---

## ⚙️ System Layers

Aalto is structured as a layered system:

1. **palette** → color identity
2. **semantic roles** → meaning assignment
3. **rendering** → highlight application
4. **perception** → visual result

Each layer has a single responsibility.

### Layer Isolation

- `base.lua` knows about color, not meaning
- `semantic.lua` knows about meaning, not specific languages
- `groups/` knows about editor features, not color theory
- `ui.lua` knows about UI patterns, not plugins

This isolation makes the system:

- Testable (each layer independently verifiable)
- Extensible (add new variants without touching semantics)
- Stable (changes don't cascade unpredictably)

---

## 🔒 Why Constraints Matter

By limiting:

- number of roles
- number of colors

Aalto increases:

- clarity
- stability
- predictability

Constraint is not restriction.

> It is a way to reduce noise and amplify signal.

---

## 👁 What Makes It Different

Most themes optimize for:

- aesthetics
- expressiveness

Aalto optimizes for:

- structure recognition
- cognitive stability
- long-term usability

It is designed to support reading, not impress at a glance.

---

## 🧭 Decision Log

### Why 4 roles, not 5 or 3?

**5 roles** (adding "type" or "variable"): Creates ambiguity. Is a function call "definition" or something else? The boundary blurs.

**3 roles** (merging string/constant): Loses important distinction between data (strings) and values (numbers/booleans).

**4 roles**: Clear separation of concerns. Structure, data, values, context. Every code element maps unambiguously to one role.

### Why OKLCH, not HSL?

HSL lightness is not perceptually uniform. Yellow at 50% lightness looks brighter than blue at 50%. OKLCH lightness is perceptually accurate, making contrast calculations reliable.

### Why dark-first design?

Dark mode is more forgiving for perceptual color work. Light mode derivation is the harder problem; solving it from dark ensures the dark experience is optimal.

### Why no language-specific colors?

Language-specific colors create inconsistency. Opening a Python file after working in Go changes the color of similar constructs. Aalto enforces consistency: a function is always `definition`, regardless of language.

---

## 🧭 Guiding Idea

> The best colorscheme is the one you stop noticing.

Not because it disappears —
but because it becomes predictable, stable, and clear.
