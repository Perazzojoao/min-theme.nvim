local M = {}

---@param colors table
---@param config ThemeConfig
---@return table<string, HighlightDefinition>
function M.get(colors, config)
  local fg = colors.fg or colors.fg1
  local panel = colors.panel_bg or colors.bg0
  local border = colors.border or colors.bg3
  local cursorline = colors.cursorline or colors.bg1
  local selection = colors.selection or colors.bg3

  return {
    -- Snacks windows install these with `default = true`, so define their
    -- surfaces before Snacks loads. Text groups below keep their own colors.
    SnacksNormal = { fg = fg, bg = panel },
    SnacksNormalNC = { fg = fg, bg = panel },
    SnacksTitle = { fg = fg, bg = panel },
    SnacksFooter = { fg = fg, bg = panel },
    SnacksWinBar = { fg = fg, bg = panel },
    SnacksWinBarNC = { fg = fg, bg = panel },
    SnacksWinSeparator = { fg = border, bg = panel },

    SnacksPicker = { fg = fg, bg = panel },
    SnacksPickerBorder = { fg = border, bg = panel },
    SnacksPickerTitle = { fg = fg, bg = panel },
    SnacksPickerFooter = { fg = fg, bg = panel },
    SnacksPickerCursorLine = { bg = cursorline },
    SnacksPickerListNormalFloat = { fg = fg, bg = panel },
    SnacksPickerListBorder = { fg = border, bg = panel },
    SnacksPickerListTitle = { fg = fg, bg = panel },
    SnacksPickerListFooter = { fg = fg, bg = panel },
    SnacksPickerListCursorLine = { bg = cursorline },
    SnacksPickerListVisual = { bg = selection },
    SnacksPickerBoxNormalFloat = { fg = fg, bg = panel },
    SnacksPickerBoxBorder = { fg = border, bg = panel },
    SnacksPickerBoxTitle = { fg = fg, bg = panel },
    SnacksPickerBoxFooter = { fg = fg, bg = panel },
    SnacksPickerBoxCursorLine = { bg = cursorline },
    SnacksPickerInputNormalFloat = { fg = fg, bg = panel },
    SnacksPickerInputBorder = { fg = border, bg = panel },
    SnacksPickerInputTitle = { fg = fg, bg = panel },
    SnacksPickerInputFooter = { fg = fg, bg = panel },
    SnacksPickerInputCursorLine = { bg = cursorline },
    -- File contents use the editor surface; picker controls retain the panel surface.
    SnacksPickerPreview = { link = "Normal" },
    SnacksPickerPreviewNormalFloat = { link = "SnacksPickerPreview" },
    SnacksPickerPreviewBorder = { fg = border, bg = panel },
    SnacksPickerPreviewTitle = { fg = fg, bg = panel },
    SnacksPickerPreviewFooter = { fg = fg, bg = panel },
    SnacksPickerPreviewCursorLine = { bg = cursorline },

    SnacksPickerMatch = { fg = colors.primary_active },
    SnacksPickerPrompt = { fg = colors.primary },
    SnacksPickerDir = { link = "ThemeGray" },
    SnacksPickerPathHidden = { link = "ThemeGray" },
    SnacksPickerGitStatusUntracked = { link = "ThemeGray" },
    SnacksPickerPathIgnored = { link = "ThemeBg3" },

    SnacksInputNormal = { fg = fg, bg = panel },
    SnacksInputBorder = { fg = border, bg = panel },
    SnacksInputTitle = { fg = colors.info, bg = panel },

    SnacksNotifierMinimal = { fg = fg, bg = panel },
    SnacksNotifierHistory = { fg = fg, bg = panel },
    SnacksNotifierHistoryTitle = { fg = fg, bg = panel },
    SnacksNotifierHistoryDateTime = { fg = colors.muted, bg = panel },
    SnacksNotifierTrace = { fg = fg, bg = panel },
    SnacksNotifierDebug = { fg = fg, bg = panel },
    SnacksNotifierInfo = { fg = fg, bg = panel },
    SnacksNotifierWarn = { fg = fg, bg = panel },
    SnacksNotifierError = { fg = fg, bg = panel },
    SnacksNotifierTitleTrace = { fg = colors.muted, bg = panel },
    SnacksNotifierTitleDebug = { fg = colors.muted, bg = panel },
    SnacksNotifierTitleInfo = { fg = colors.info, bg = panel },
    SnacksNotifierTitleWarn = { fg = colors.warning, bg = panel },
    SnacksNotifierTitleError = { fg = colors.primary, bg = panel },
    SnacksNotifierIconTrace = { fg = colors.muted, bg = panel },
    SnacksNotifierIconDebug = { fg = colors.muted, bg = panel },
    SnacksNotifierIconInfo = { fg = colors.info, bg = panel },
    SnacksNotifierIconWarn = { fg = colors.warning, bg = panel },
    SnacksNotifierIconError = { fg = colors.primary, bg = panel },
    SnacksNotifierBorderTrace = { fg = colors.muted, bg = panel },
    SnacksNotifierBorderDebug = { fg = colors.muted, bg = panel },
    SnacksNotifierBorderInfo = { fg = colors.info, bg = panel },
    SnacksNotifierBorderWarn = { fg = colors.warning, bg = panel },
    SnacksNotifierBorderError = { fg = colors.primary, bg = panel },
    SnacksNotifierFooterTrace = { fg = colors.muted, bg = panel },
    SnacksNotifierFooterDebug = { fg = colors.muted, bg = panel },
    SnacksNotifierFooterInfo = { fg = colors.info, bg = panel },
    SnacksNotifierFooterWarn = { fg = colors.warning, bg = panel },
    SnacksNotifierFooterError = { fg = colors.primary, bg = panel },
  }
end

return M
