local M = {}

local function resolve(groups, name, seen)
  seen = seen or {}
  if seen[name] then
    return {}
  end
  seen[name] = true
  local attrs = groups[name] or {}
  if attrs.link then
    return resolve(groups, attrs.link, seen)
  end
  return vim.deepcopy(attrs)
end

local function apply_overrides(groups, overrides)
  local function final(name, seen)
    seen = seen or {}
    if seen[name] then
      return {}
    end
    seen[name] = true
    local attrs = groups[name] or {}
    local custom = overrides[name] or {}
    if custom.link then
      return final(custom.link, seen)
    end
    local base = attrs.link and final(attrs.link, seen) or vim.deepcopy(attrs)
    return vim.tbl_extend("force", base, custom)
  end
  local pending = vim.deepcopy(groups)
  for name, attrs in pairs(overrides) do
    pending[name] = attrs.link and vim.deepcopy(attrs) or final(name)
  end
  return pending
end

function M.get(colors, config)
  local groups = {}
  for _, mod in ipairs({ "base", "editor", "syntax", "diagnostics", "treesitter", "plugins" }) do
    groups = vim.tbl_extend("force", groups, require("min-theme.groups." .. mod).get(colors, config))
  end

  local defaults = require("min-theme.defaults")
  local compiled = require("min-theme.vscode").build_overrides(defaults.get(colors), defaults.get_ui(colors))
  for name, attrs in pairs(compiled) do
    local old = vim.deepcopy(groups[name] or {})
    old.link = nil
    groups[name] = attrs.link and vim.deepcopy(attrs) or vim.tbl_extend("force", old, attrs)
  end
  -- The off-white is contextual, never an unconditional declaration modifier.
  for _, kind in ipairs({ "variable", "field", "property" }) do
    for _, modifier in ipairs({ "declaration", "definition" }) do
      groups["@lsp.typemod." .. kind .. "." .. modifier] = { link = "@variable" }
    end
  end
  groups.MinThemeHtmlTagName = { link = "htmlTagName" }
  groups.LspSignatureActiveParameter = { bold = config.bold, italic = true }
  groups.RenderMarkdownCode = { bg = colors.panel_bg }
  groups.RenderMarkdownCodeBorder = { link = "RenderMarkdownCode" }

  if config.italic.strings then
    groups.String.italic = true
    groups["@string"].italic = true
    groups["@lsp.type.string"].italic = true
  end
  if config.italic.comments then
    for _, name in ipairs({ "Comment", "@comment", "@comment.documentation", "@lsp.type.comment" }) do
      groups[name].italic = true
    end
  end
  if config.italic.operators then
    groups.Operator.italic = true
    groups["@operator"].italic = true
  end
  if not config.italic.emphasis then
    for _, name in ipairs({ "@text.emphasis", "@markup.italic", "markdownItalic", "markdownBoldItalic" }) do
      groups[name].italic = false
    end
  end
  if config.invert_selection then
    groups.Visual.reverse = true
  end
  if not config.bold then
    for _, attrs in pairs(groups) do
      if attrs.bold then
        attrs.bold = false
      end
    end
  end
  if not config.underline then
    for _, attrs in pairs(groups) do
      if attrs.underline then
        attrs.underline = false
      end
    end
  end
  if not config.strikethrough then
    groups.DiagnosticDeprecated.strikethrough = false
    groups["@lsp.mod.deprecated"].strikethrough = false
  end
  if config.dim_inactive then
    groups.NormalNC = { fg = colors.fg0, bg = colors.bg1 }
  end
  if config.transparent_mode then
    for _, name in ipairs({ "Normal", "NormalNC", "SignColumn", "FoldColumn", "EndOfBuffer", "WinSeparator", "WinBar" }) do
      groups[name] = resolve(groups, name)
      groups[name].bg = nil
    end
    for name, attrs in pairs(groups) do
      if name:match("^Theme.*Sign$") then
        attrs.bg = nil
      end
    end
  end

  -- Read final tabline parents (including caller changes) for static Bufferline
  -- groups. Icon backgrounds are synchronized separately by the guarded shim.
  local with_overrides = apply_overrides(groups, config.overrides)
  colors.diagnostics = {}
  for kind, name in pairs({
    error = "DiagnosticError",
    warning = "DiagnosticWarn",
    info = "DiagnosticInfo",
    hint = "DiagnosticHint",
  }) do
    colors.diagnostics[kind] = resolve(with_overrides, name).fg
  end
  colors.tab = resolve(with_overrides, "TabLine")
  colors.tab_selected = resolve(with_overrides, "TabLineSel")
  colors.tab_fill = resolve(with_overrides, "TabLineFill")
  if config.integrations.bufferline then
    groups = vim.tbl_extend("force", groups, require("min-theme.groups.plugins.bufferline").get(colors, config))
  end

  local optional_prefixes = {
    snacks = { "Snacks" },
    blink = { "BlinkCmp" },
    render_markdown = { "RenderMarkdown" },
    gitsigns = { "GitSigns" },
    bufferline = { "BufferLine" },
  }
  for integration, prefixes in pairs(optional_prefixes) do
    if not config.integrations[integration] then
      for name in pairs(groups) do
        for _, prefix in ipairs(prefixes) do
          if name:sub(1, #prefix) == prefix then
            groups[name] = nil
          end
        end
      end
    end
  end
  return apply_overrides(groups, config.overrides)
end

return M
