# min-theme.nvim

Min Dark for Neovim 0.10+, with the VS Code Min Dark colors and this fork's default editor behavior. Loading the colorscheme applies the default highlights. Bufferline icon backgrounds use the public configuration shown below.

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
| Explorer, plugin menus and floating windows | `#121212` background |
| Native autocomplete (`:`, `/`, `?`) | `#161616` background |
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

Native diagnostic signs and Gitsigns use the editor background. Rendered Markdown code blocks apply background only so injected code keeps its syntax colors. Bufferline's selected, visible and inactive tabs use the theme palette; Snacks pickers, explorer, input and notification windows share the menu palette. File preview contents inherit `Normal` and keep the editor background; preview borders and titles retain the menu surface.

## Optional integrations and fallback

The theme works without LSP clients, Tree-sitter parsers or third-party plugins. It does not install or start servers, parsers or plugins. Native LSP semantic tokens supply symbol identity; available native Tree-sitter parsers refine variable access and identify parameter bindings. The first contextual grammars supported are C#, Java, JavaScript, TypeScript, TSX, Lua, Python and Go. Other languages keep their normal syntax and semantic highlight groups.

If classification is missing, disabled or fails, variables remain blue without the declaration/usage distinction. Identifiable parameters stay orange using available syntax or semantic metadata. A name whose parameter identity is unavailable cannot be guessed reliably and keeps its normal fallback. Bindings use lexical scopes rather than parameter-name matching across the whole buffer.

While typing, existing classifications remain visible until their replacements are ready. Semantic roles use Neovim's `vim.lsp.semantic_tokens.highlight_token()` lifecycle, which tracks edits and replaces highlights with each new token snapshot, including removed symbols and changed categories. Syntax roles are rebuilt after edits with a per-buffer 30 ms debounce and without clearing them during that interval; unchanged buffers reuse their rendered classifications. Disabling the integration or switching themes requests a native semantic refresh to remove the theme's overrides and rebuild other token consumers.

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

Bufferline integration provides static `BufferLine*` highlights only; the theme does not wrap plugin functions or modify Bufferline's configuration. To make generated icon backgrounds match the tabs, merge these public references into your existing Bufferline setup (load the colorscheme before setup):

```lua
require("bufferline").setup({
  highlights = {
    background = { bg = { highlight = "TabLine", attribute = "bg" } },
    buffer_visible = { bg = { highlight = "TabLine", attribute = "bg" } },
    buffer_selected = {
      bg = { highlight = "TabLineSel", attribute = "bg" },
      bold = true,
      italic = false,
    },
  },
})
```

Bufferline refreshes these references on colorscheme changes. Without the references, its own background shading applies to generated icons. With `options.themable = false`, Bufferline's configuration takes precedence over the theme's static groups. Theme switches remove owned overlays and callbacks; reloading the theme is idempotent.

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
nvim --headless -u NONE -i NONE -l tests/semantic_lifecycle.lua
nvim --headless -u NONE -i NONE -l tests/bufferline_integration.lua
```

Role checks require native parsers for the eight supported grammars on the runtimepath. Missing-parser and disabled-provider fallback are also tested explicitly. The Bufferline integration check uses the installed plugin; set `BUFFERLINE_RTP` to test another checkout.

The semantic lifecycle check uses an in-process LSP with delayed responses and the native semantic engine. It checks continuous typing, symbol movement/removal, category changes, reloads, integration toggles, theme switches and multiple clients. It requires the JavaScript parser but no external language server.

## License

MIT. The original Neovim theme attribution remains in `LICENSE`; the bundled VS Code palette attribution is in `LICENSE.min-theme-vscode`.
