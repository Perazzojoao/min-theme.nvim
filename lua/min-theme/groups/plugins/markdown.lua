local M = {}

---@param colors table
---@param config ThemeConfig
---@return table<string, HighlightDefinition>
function M.get(colors, config)
  local code_bg = colors.panel_bg or colors.bg0

  return {
    markdownItalic = { fg = colors.fg3, italic = true },
    markdownBold = { fg = colors.primary_active, bold = config.bold },
    markdownBoldItalic = { fg = colors.primary_active, bold = config.bold, italic = true },
    markdownH1 = { fg = colors.primary_active, bold = config.bold },
    markdownH2 = { fg = colors.primary_active, bold = config.bold },
    markdownH3 = { fg = colors.primary_active, bold = config.bold },
    markdownH4 = { fg = colors.secondary, bold = config.bold },
    markdownH5 = { link = "ThemeSecondary" },
    markdownH6 = { link = "ThemeSecondary" },
    -- Keep code backgrounds separate from syntax foregrounds so injected
    -- language highlighting remains visible inside fenced blocks.
    markdownCode = { bg = code_bg },
    markdownCodeBlock = { bg = code_bg },
    markdownCodeDelimiter = { bg = code_bg },
    markdownCodeBorder = { bg = code_bg },
    ["@markup.raw"] = { bg = code_bg },
    ["@markup.raw.block"] = { bg = code_bg },
    ["@markup.raw.inline"] = { bg = code_bg },
    markdownBlockquote = { link = "ThemeGray" },
    markdownListMarker = { fg = colors.primary_active },
    markdownOrderedListMarker = { fg = colors.primary_active },
    markdownRule = { link = "ThemeGray" },
    markdownHeadingRule = { link = "ThemeGray" },
    markdownUrlDelimiter = { link = "ThemeFg3" },
    markdownLinkDelimiter = { link = "ThemeFg3" },
    markdownLinkTextDelimiter = { link = "ThemeFg3" },
    markdownHeadingDelimiter = { fg = colors.primary_active },
    markdownUrl = { fg = colors.primary_soft, underline = config.underline },
    markdownUrlTitleDelimiter = { fg = colors.primary_soft },
    markdownLinkText = { fg = colors.secondary_active, underline = config.underline },
    markdownIdDeclaration = { link = "markdownLinkText" },
  }
end

return M
