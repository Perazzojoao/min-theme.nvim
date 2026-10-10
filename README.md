# min-theme.nvim

Min Dark for Neovim 0.10+, with the VS Code Min Dark colors and this fork's default editor behavior. Loading the colorscheme is enough; no overrides or plugin integrations need to be configured.

```lua
-- After installing Perazzojoao/min-theme.nvim with your plugin manager:
vim.cmd.colorscheme("min-theme")
```

With lazy.nvim:

```lua
{
  "Perazzojoao/min-theme.nvim",
  lazy = false,
  priority = 1000,
}
```

For a local checkout:

```lua
vim.opt.runtimepath:prepend(vim.fn.expand("~/Dev/Personal/min-theme.nvim"))
vim.cmd.colorscheme("min-theme")
```

## Defaults

| Role | Color / behavior |
| --- | --- |
| Editor | `#121212` background, `#cfcfcf` foreground |
| Explorer, menus and floating windows | `#121212` background |
| Current line | `#181818` background |
| Visual selection | `#2a2a2a` background, preserves syntax foreground |
| Links | `#368cfc` |
| Menu and completion matches | `#f97583` foreground; preserves background |
| Editor search matches | Original `Search` / `IncSearch` accents and inversion |
| Variables, without contextual classification | `#79b8ff` |
| Classified declaration or standalone variable | `#cfcfcf` |
| Variable receiver and accessed properties | `#79b8ff` |
| Parameter declaration and references | `#FF9800` |
| Types and functions | `#b392f0` |
| Strings and HTML/XML tag names | `#ffab70` |
| Punctuation, including HTML/XML tag delimiters | `#bbbbbb` |
| Active signature parameter | Bold and italic; preserves foreground and background |

Native diagnostic signs and Gitsigns use the editor background. Rendered Markdown code blocks apply background only so injected code keeps its syntax colors. Bufferline's selected, visible and inactive tabs include matching icon backgrounds; Snacks pickers, explorer, input and notification windows share the menu palette. File preview contents inherit `Normal` and keep the editor background; preview borders and titles retain the menu surface.

## Optional integrations and fallback

The theme works without LSP clients, Tree-sitter parsers or third-party plugins. It does not install or start servers, parsers or plugins. Native LSP semantic tokens supply symbol identity; available native Tree-sitter parsers refine variable access and identify parameter bindings. The first contextual grammars supported are C#, Java, JavaScript, TypeScript, TSX, Lua, Python and Go. Other languages keep their normal syntax and semantic highlight groups.

If classification is missing, disabled or fails, variables remain blue without the declaration/usage distinction. Identifiable parameters stay orange using available syntax or semantic metadata. A name whose parameter identity is unavailable cannot be guessed reliably and keeps its normal fallback. Bindings use lexical scopes rather than parameter-name matching across the whole buffer.

All integrations default to enabled:

```lua
require("min-theme").setup({
  variable_roles = true,
  integrations = {
    lsp = true,
    treesitter = true,
    gitsigns = true,
    bufferline = true,
    snacks = true,
    blink = true,
    render_markdown = true,
  },
})
vim.cmd.colorscheme("min-theme")
```

The Bufferline icon adapter checks for the supported highlight API and respects `options.themable = false`. It does not call Bufferline setup or change user options. An unavailable adapter leaves the static theme groups as fallback. Theme switches remove owned overlays, callbacks and adapters; reloading the theme is idempotent.

## Customization

The existing setup API remains available. Partial overrides retain the other attributes, including colors inherited through links. Explicit `link` overrides replace the group. Overrides are applied last.

```lua
require("min-theme").setup({
  overrides = {
    Comment = { italic = true },
    NormalFloat = { bg = "#1c1c1c" },
    CursorLine = { bg = "#202020" },
  },
})
vim.cmd.colorscheme("min-theme")
```

Other options: `terminal_colors`, `undercurl`, `underline`, `bold`, `italic` (`strings`, `comments`, `operators`, `folds`, `emphasis`), `strikethrough`, `inverse`, `invert_selection`, `invert_signs`, `invert_tabline`, `contrast` (`""`, `"soft"`, `"hard"`), `dim_inactive`, `transparent_mode`. Strings and comments default to nonitalic.

## Source and verification

The package contains the complete pinned [VS Code Min Dark source](https://github.com/miguelsolorio/min-theme/blob/dd796c3f294daecfb7f10ed277ffdc30517d59cf/themes/min-dark.json) in `lua/min-theme/resources/min-dark-vscode-color-map.json`: 84 UI color occurrences and 21 token color occurrences, with source metadata and MIT attribution. Neovim categories are explicit adaptations of TextMate scopes, not a full TextMate selector implementation. Personal choices listed above take precedence over the original editor surfaces.

`require("min-theme.vscode").audit()` returns the 105 source occurrences with their Neovim mapping or the reason they have no equivalent. See [the mapping notes](docs/colors.md). The theme needs no dotfiles or external palette file.

From the checkout, run the standalone checks:

```sh
nvim --headless -u NONE -i NONE -l tests/theme.lua
nvim --headless -u NONE -i NONE -l tests/roles.lua
nvim --headless -u NONE -i NONE -l tests/bufferline.lua
nvim --headless -u NONE -i NONE -l tests/bufferline_integration.lua
```

Role checks require native parsers for the eight supported grammars on the runtimepath. Missing-parser and disabled-provider fallback are also tested explicitly. See each test's header for additional plugin/runtime paths when testing the real Bufferline adapter.

## License

MIT. The original Neovim theme attribution remains in `LICENSE`; the bundled VS Code palette attribution is in `LICENSE.min-theme-vscode`.
