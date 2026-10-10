-- The audited VS Code mapping plus the fork's chosen default surfaces and behavior.
local M = {}

function M.get(colors)
  local bg, fg, panel = colors.bg0, colors.fg1, colors.panel_bg
  return {
    Normal = { fg = fg, bg = bg },
    NormalNC = { link = "Normal" },
    ThemeFg1 = { fg = fg },
    Visual = { bg = colors.selection },
    VisualNOS = { link = "Visual" },
    CursorLine = { bg = colors.cursorline },
    CursorLineNr = { fg = colors.fg4, bg = colors.cursorline },
    SignColumn = { bg = bg },
    ThemePrimarySign = { bg = bg },
    ThemeWarningSign = { bg = bg },
    ThemeInfoSign = { bg = bg },
    ThemeSecondarySoftSign = { bg = bg },
    ThemeSuccessSign = { bg = bg },
    ThemeGitAddedSign = { bg = bg },
    ThemeGitModifiedSign = { bg = bg },
    ThemeGitDeletedSign = { bg = bg },
    FoldColumn = { bg = bg },
    EndOfBuffer = { bg = bg },
    WinSeparator = { bg = bg },
    WinBar = { bg = bg },
    SnacksPicker = { fg = fg, bg = panel },
    SnacksPickerBox = { link = "SnacksPicker" },
    NormalFloat = { fg = fg, bg = panel },
    FloatBorder = { fg = colors.border, bg = panel },
    FloatTitle = { bg = panel },
    FloatFooter = { bg = panel },
    LspSignatureActiveParameter = { bold = true, italic = true },
    Pmenu = { fg = fg, bg = colors.cmdline_bg },
    PmenuSbar = { bg = colors.cmdline_bg },
    -- Keep Blink's surface separate from the native command-line popup.
    BlinkCmpMenu = { fg = fg, bg = panel },
    BlinkCmpMenuBorder = { fg = fg, bg = panel },
    SnacksInputNormal = { link = "NormalFloat" },
    SnacksNotifierHistory = { link = "NormalFloat" },
    Underlined = { fg = colors.link, underline = true },
    ["@markup.link"] = { fg = colors.link, underline = true },
    ["@markup.link.label"] = { fg = colors.link },
    ["@text.uri"] = { fg = colors.link, underline = true },
    markdownUrl = { fg = colors.link },
    markdownLinkText = { fg = colors.link },
    RenderMarkdownLink = { link = "Underlined" },
    -- Only the role engine applies these to known variables. Semantic declaration
    -- modifiers stay blue so a missing/disabled provider has a uniform fallback.
    ["@variable.declaration"] = { fg = fg },
    ["@variable.standalone"] = { fg = fg },
  }
end

-- UI keys are global theme roles, shared by every mapped consumer.
function M.get_ui(colors)
  return { ["list.highlightForeground"] = colors.match }
end

return M
