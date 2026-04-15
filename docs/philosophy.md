# Philosophy

Aalto starts with an uncomfortable question: **what is color actually doing in
your editor?**

For most colorschemes, the honest answer is: making it look interesting. There
is nothing wrong with that — aesthetics matter, and a beautiful editor is a
pleasant place to spend time. But Aalto is not trying to be beautiful. It is
trying to be useful.

---

## Color as a scarce resource

The human visual system is good at tracking a small number of distinct signals
simultaneously. When everything is colored, nothing is — the colors cancel each
other out and become wallpaper. When only a few things are colored, those things
stand out clearly and the coloring carries real information.

Aalto treats color as scarce. Every color must justify its existence by
answering the question: _what does this color tell the reader that they could
not otherwise determine?_

---

## What color can tell you

Color can communicate one thing reliably: **category membership**. It answers
"what kind of thing is this?" — not "what does this do?" or "is this
important?", which require understanding the code.

Aalto picks four categories that are universal across programming languages and
meaningful to the way programmers think about code:

**Definition** — Things that create structure. Functions, types, classes,
modules, interfaces. These are the anchors of a codebase. When you scan a file,
you are usually scanning for definitions.

**Constant** — Things that hold values. Numbers, booleans, enum members. These
are the concrete facts in the code — things that do not change and do not need
to be traced.

**String** — Things that carry data. String literals, character literals. These
are the external world leaking into code — file paths, messages, configuration,
content.

**Comment** — Things that are not executed. Comments, documentation. These exist
for the reader, not the compiler.

Everything else — keywords, operators, punctuation, variable names — is rendered
in neutral foreground. Not because those things are unimportant, but because
they do not belong to a category that color can helpfully signal. The keyword
`function` and the keyword `if` are both just keywords; coloring them
differently would add noise without adding meaning.

---

## Meaning over syntax

Most colorschemes are syntax-driven. They start with the grammar of the language
and assign colors to token types: keywords are one color, built-ins are another,
operators are a third. This produces visually complex output that looks detailed
and informative.

The problem is that syntax coloring is local. It tells you the grammatical
category of a token, not its semantic role. In many languages, `true` is a
keyword, a built-in constant, or a predefined identifier depending on how the
grammar is structured — so syntax-driven themes color it differently across
languages, even though it means the same thing everywhere.

Aalto is role-driven. It asks: what is this thing _doing_? A function definition
gets `definition` color regardless of whether the language marks it with
`function`, `def`, `fn`, `func`, or a sigil. A numeric literal gets `constant`
color regardless of whether it is an integer, a float, a hex value, or a
scientific notation. The same role always looks the same.

---

## Perception over decoration

The colors themselves are not chosen for appearance. They are chosen to maintain
a stable perceptual hierarchy — definition is always more prominent than
constant, constant more prominent than string, string more prominent than
comment.

This is implemented through the OKLCH color space. OKLCH models how humans
perceive color (specifically, it equalizes perceptual lightness across hues), so
contrast ratios computed in OKLCH correspond to what the eye actually notices. A
definition and a comment with the same OKLCH lightness difference will look
equally distinct regardless of their hues.

The result is that the hierarchy feels natural rather than forced. You do not
need to consciously track "blue means function" — you just notice that functions
are slightly more prominent, and that prominence pulls your eye to structure.

---

## What Aalto is not for

Aalto is not for learning a language. When you are still internalizing the
grammar of a new language, rich syntax coloring helps — different colors for
keywords, types, and built-ins give you a visual scaffold while the grammar is
not yet automatic. Aalto assumes the grammar is already automatic and gets out
of the way.

Aalto is not for visual expression. If you want your editor to look like a
painting, or if you derive genuine pleasure from a richly colored syntax
display, Aalto will feel sparse. That is a legitimate preference, and Aalto is
not the right tool for it.

Aalto is not for per-language customization. The semantic roles are
intentionally universal. There is no mechanism to color Python differently from
Rust — that would defeat the point.

---

## What Aalto is for

Aalto is for long working sessions where the code is familiar and the goal is
thinking, not parsing. It is for people who find rich syntax coloring
distracting once the grammar is internalized. It is for codebases where
structure matters — where knowing at a glance where the definitions are, what
the constants are, and where the data flows is genuinely useful.

The ideal outcome is that you stop noticing the colorscheme. The definitions
anchor your eye automatically. The comments fade without effort. The strings and
constants register without demanding attention. The theme becomes infrastructure
— present and functional, but invisible.

> The best colorscheme is the one you stop noticing.
