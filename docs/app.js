// Aalto Showroom
(function () {
  "use strict";

  const DARK_PALETTE = {
    bg: "#18122E",
    fg: "#EAE1D8",
    fg_dark: "#706873",
    fg_light: "#F5F0E6",
    blue: "#6B7FD4",
    magenta: "#B87333",
    green: "#7D8F6E",
    red: "#C46B6B",
    orange: "#D4A373",
    cyan: "#6B9A92",
  };

  const LIGHT_PALETTE = {
    bg: "#F2EDE6",
    fg: "#2B2740",
    fg_dark: "#9A948C",
    fg_light: "#4A4656",
    blue: "#5C63C0",
    magenta: "#8A5A3C",
    green: "#61784F",
    red: "#9C4A4A",
    orange: "#8A6B4A",
    cyan: "#4F7A70",
  };

  const LANGUAGES = [
    "rust",
    "python",
    "go",
    "elixir",
    "typescript",
    "lua",
    "c",
    "bash",
    "ruby",
    "clojure",
  ];

  let currentVariant = "dark";
  let currentPalette = { ...DARK_PALETTE };

  const codeEl = document.getElementById("code-sample");
  const variantCheckbox = document.getElementById("variant-checkbox");
  const languageSelect = document.getElementById("language-select");
  const paletteGrid = document.getElementById("palette-grid");
  const paletteTitle = document.getElementById("palette-title");
  const toast = document.getElementById("toast");

  function populateLanguages() {
    languageSelect.innerHTML = LANGUAGES.map(
      (lang) =>
        `<option value="${lang}">${
          lang.charAt(0).toUpperCase() + lang.slice(1)
        }</option>`,
    ).join("");
  }
  populateLanguages();

  function applyPaletteToDOM(palette) {
    const root = document.documentElement;
    const isLight = currentVariant === "light";
    root.setAttribute("data-theme", isLight ? "light" : "dark");

    document.body.style.backgroundColor = palette.bg;
    document.body.style.color = palette.fg;
  }

  function renderPaletteTable(palette) {
    const displayOrder = [
      "bg",
      "fg",
      "blue",
      "magenta",
      "green",
      "fg_dark",
      "fg_light",
      "red",
      "orange",
      "cyan",
    ];
    const names = {
      bg: "Background",
      fg: "Foreground",
      blue: "Definition",
      magenta: "Constant",
      green: "String",
      fg_dark: "Comment",
      fg_light: "UI Accent",
      red: "Error",
      orange: "Warning",
      cyan: "Info",
    };

    paletteGrid.innerHTML = displayOrder
      .map((key) => {
        const hex = palette[key];
        return `
        <div class="palette-row">
          <div class="palette-label">
            <span class="color-swatch" style="background: ${hex};"></span>
            <span>${names[key] || key}</span>
          </div>
          <div class="palette-value" data-hex="${hex}" title="Click to copy">
            ${hex} <span class="copy-icon">📋</span>
          </div>
        </div>
      `;
      })
      .join("");

    document.querySelectorAll(".palette-value").forEach((el) => {
      el.addEventListener("click", () => {
        const hex = el.dataset.hex;
        navigator.clipboard?.writeText(hex).then(() =>
          showToast(`Copied ${hex}`)
        );
      });
    });

    paletteTitle.textContent = currentVariant === "dark"
      ? "Dark Palette"
      : "Light Palette";
  }

  async function loadSample(lang) {
    try {
      const res = await fetch(`samples/${lang}.txt`);
      if (!res.ok) throw new Error("Sample not found");
      const code = await res.text();
      codeEl.textContent = code;
      codeEl.className = `language-${lang}`;
      Prism.highlightElement(codeEl);
    } catch (e) {
      codeEl.textContent = `// Could not load ${lang} sample.`;
    }
  }

  function showToast(message) {
    toast.textContent = message;
    toast.classList.remove("hidden");
    setTimeout(() => toast.classList.add("hidden"), 2000);
  }

  function updateVariant() {
    currentPalette = currentVariant === "dark"
      ? { ...DARK_PALETTE }
      : { ...LIGHT_PALETTE };
    applyPaletteToDOM(currentPalette);
    renderPaletteTable(currentPalette);
    if (codeEl.textContent) {
      Prism.highlightElement(codeEl);
    }
  }

  variantCheckbox.addEventListener("input", (e) => {
    currentVariant = e.target.checked ? "light" : "dark";
    updateVariant();
  });

  languageSelect.addEventListener("change", (e) => {
    loadSample(e.target.value);
  });

  variantCheckbox.checked = false;
  updateVariant();
  loadSample("rust");
})();
