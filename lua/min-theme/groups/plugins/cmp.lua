local M = {}

---@param colors table
---@param config ThemeConfig
---@return table<string, HighlightDefinition>
function M.get(colors, config)
  local fg = colors.fg or colors.fg1
  local panel = colors.panel_bg or colors.bg0
  local border = colors.border or colors.bg3
  local selection = colors.selection or colors.bg3

  -- Min Dark symbolIcon mapping:
  -- class/enum/event → #FF9800 (orange/primary_muted)
  -- method/constructor/function → #b392f0 (purple/secondary)
  -- field/interface/variable/enumMember → #79b8ff (blue/secondary_active)
  return {
    -- Blink Cmp
    BlinkCmpMenu = { fg = fg, bg = panel },
    BlinkCmpMenuBorder = { fg = border, bg = panel },
    BlinkCmpMenuSelection = { bg = selection },
    BlinkCmpDoc = { fg = fg, bg = panel },
    BlinkCmpDocBorder = { fg = border, bg = panel },
    BlinkCmpDocSeparator = { fg = border, bg = panel },
    BlinkCmpDocCursorLine = { bg = selection },
    BlinkCmpSignatureHelp = { fg = fg, bg = panel },
    BlinkCmpSignatureHelpBorder = { fg = border, bg = panel },

    BlinkCmpLabel = { link = "ThemeFg0" },
    BlinkCmpLabelDeprecated = { link = "ThemeFg1" },
    BlinkCmpLabelMatch = { link = "ThemeSecondaryActiveBold" },
    BlinkCmpLabelDetail = { link = "ThemeGray" },
    BlinkCmpLabelDescription = { link = "ThemeGray" },
    BlinkCmpKindText = { link = "ThemeFg1" },
    BlinkCmpKindVariable = { link = "ThemeSecondaryActive" },
    BlinkCmpKindMethod = { link = "ThemeSecondary" },
    BlinkCmpKindFunction = { link = "ThemeSecondary" },
    BlinkCmpKindConstructor = { link = "ThemeSecondary" },
    BlinkCmpKindUnit = { link = "ThemeFg0" },
    BlinkCmpKindField = { link = "ThemeSecondaryActive" },
    BlinkCmpKindClass = { link = "ThemeSecondaryActive" },
    BlinkCmpKindInterface = { link = "ThemeSecondaryActive" },
    BlinkCmpKindModule = { link = "ThemeFg1" },
    BlinkCmpKindProperty = { link = "ThemeSecondaryActive" },
    BlinkCmpKindValue = { link = "ThemeFg0" },
    BlinkCmpKindEnum = { link = "ThemeSecondaryActive" },
    BlinkCmpKindOperator = { link = "ThemeSecondary" },
    BlinkCmpKindKeyword = { link = "ThemePrimary" },
    BlinkCmpKindEvent = { link = "ThemeSecondaryActive" },
    BlinkCmpKindReference = { link = "ThemeSecondaryActive" },
    BlinkCmpKindColor = { link = "ThemeFg0" },
    BlinkCmpKindSnippet = { link = "ThemeSecondary" },
    BlinkCmpKindFile = { link = "ThemeFg1" },
    BlinkCmpKindFolder = { link = "ThemeFg1" },
    BlinkCmpKindEnumMember = { link = "ThemeSecondaryActive" },
    BlinkCmpKindConstant = { link = "ThemeSecondaryActive" },
    BlinkCmpKindStruct = { link = "ThemeSecondaryActive" },
    BlinkCmpKindTypeParameter = { link = "ThemeSecondaryActive" },
    BlinkCmpSource = { link = "ThemeGray" },
    BlinkCmpGhostText = { link = "ThemeBg4" },
    -- nvim-cmp
    CmpPmenu = { fg = fg, bg = panel },
    CmpDocumentation = { fg = fg, bg = panel },
    CmpDocumentationBorder = { fg = border, bg = panel },
    CmpItemAbbr = { link = "ThemeFg0" },
    CmpItemAbbrDeprecated = { link = "ThemeFg1" },
    CmpItemAbbrMatch = { link = "ThemeSecondaryActiveBold" },
    CmpItemAbbrMatchFuzzy = { link = "ThemeSecondaryActiveUnderline" },
    CmpItemMenu = { link = "ThemeGray" },
    CmpItemKindText = { link = "ThemeFg1" },
    CmpItemKindVariable = { link = "ThemeSecondaryActive" },
    CmpItemKindMethod = { link = "ThemeSecondary" },
    CmpItemKindFunction = { link = "ThemeSecondary" },
    CmpItemKindConstructor = { link = "ThemeSecondary" },
    CmpItemKindUnit = { link = "ThemeFg0" },
    CmpItemKindField = { link = "ThemeSecondaryActive" },
    CmpItemKindClass = { link = "ThemeSecondaryActive" },
    CmpItemKindInterface = { link = "ThemeSecondaryActive" },
    CmpItemKindModule = { link = "ThemeFg1" },
    CmpItemKindProperty = { link = "ThemeSecondaryActive" },
    CmpItemKindValue = { link = "ThemeFg0" },
    CmpItemKindEnum = { link = "ThemeSecondaryActive" },
    CmpItemKindOperator = { link = "ThemeSecondary" },
    CmpItemKindKeyword = { link = "ThemePrimary" },
    CmpItemKindEvent = { link = "ThemeSecondaryActive" },
    CmpItemKindReference = { link = "ThemeSecondaryActive" },
    CmpItemKindColor = { link = "ThemeFg0" },
    CmpItemKindSnippet = { link = "ThemeSecondary" },
    CmpItemKindFile = { link = "ThemeFg1" },
    CmpItemKindFolder = { link = "ThemeFg1" },
    CmpItemKindEnumMember = { link = "ThemeSecondaryActive" },
    CmpItemKindConstant = { link = "ThemeSecondaryActive" },
    CmpItemKindStruct = { link = "ThemeSecondaryActive" },
    CmpItemKindTypeParameter = { link = "ThemeSecondaryActive" },
  }
end

return M
