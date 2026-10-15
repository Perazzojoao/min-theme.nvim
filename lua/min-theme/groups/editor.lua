local M = {}

---@param colors table
---@param config ThemeConfig
---@return table<string, HighlightDefinition>
function M.get(colors, config)
  return {
    Normal = config.transparent_mode and { fg = colors.fg1, bg = nil } or { fg = colors.fg1, bg = colors.bg0 },
    NormalFloat = config.transparent_mode and { fg = colors.fg1, bg = nil } or { fg = colors.fg1, bg = colors.bg1 },
    NormalNC = config.dim_inactive and { fg = colors.fg0, bg = colors.bg1 } or { link = "Normal" },
    CursorLine = { bg = colors.bg1 },
    CursorColumn = { link = "CursorLine" },
    TabLineFill = config.transparent_mode and { fg = colors.bg4, bg = nil, reverse = config.invert_tabline }
      or { fg = colors.bg4, bg = colors.bg1, reverse = config.invert_tabline },
    TabLineSel = config.transparent_mode and { fg = colors.fg0, bg = nil, reverse = config.invert_tabline }
      or { fg = colors.fg0, bg = colors.bg1, reverse = config.invert_tabline },
    TabLine = { link = "TabLineFill" },
    MatchParen = { bg = colors.bg3, bold = config.bold },
    ColorColumn = { bg = colors.bg1 },
    Conceal = { fg = colors.muted },
    CursorLineNr = { fg = colors.fg0, bg = colors.bg1 },
    NonText = { link = "ThemeBg2" },
    SpecialKey = { link = "ThemeFg4" },
    Visual = { bg = colors.bg3, reverse = config.invert_selection },
    VisualNOS = { link = "Visual" },
    -- Editor search uses its original accents, independently of menu matches.
    Search = { fg = colors.primary_active, bg = colors.bg0, reverse = config.inverse },
    IncSearch = { fg = colors.primary_soft, bg = colors.bg0, reverse = config.inverse },
    CurSearch = { link = "IncSearch" },
    QuickFixLine = { link = "ThemeSecondaryActive" },
    Underlined = { fg = colors.secondary_active, underline = config.underline },
    StatusLine = { fg = colors.fg3, bg = colors.bg1 },
    StatusLineNC = { fg = colors.bg4, bg = colors.bg1 },
    WinBar = { fg = colors.fg4, bg = colors.bg0 },
    WinBarNC = { fg = colors.fg3, bg = colors.bg1 },
    WinSeparator = config.transparent_mode and { fg = colors.bg3, bg = nil } or { fg = colors.bg3, bg = colors.bg0 },
    WildMenu = { fg = colors.fg0, bg = colors.bg2, bold = config.bold },
    Directory = { link = "ThemeSecondaryBold" },
    Title = { link = "ThemeSecondaryBold" },
    ErrorMsg = { fg = colors.bg0, bg = colors.primary, bold = config.bold },
    MoreMsg = { link = "ThemeSecondaryBold" },
    ModeMsg = { link = "ThemeSecondaryBold" },
    Question = { link = "ThemeSecondaryActiveBold" },
    WarningMsg = { link = "ThemeWarning" },
    LineNr = { fg = colors.fg4 },
    SignColumn = config.transparent_mode and { bg = nil } or { bg = colors.bg1 },
    Folded = { fg = colors.muted, bg = colors.bg1, italic = config.italic.folds },
    FoldColumn = config.transparent_mode and { fg = colors.muted, bg = nil } or { fg = colors.muted, bg = colors.bg1 },
    Cursor = { reverse = config.inverse },
    vCursor = { link = "Cursor" },
    iCursor = { link = "Cursor" },
    lCursor = { link = "Cursor" },
    Pmenu = { fg = colors.fg1, bg = colors.bg1 },
    PmenuMatch = { fg = colors.match, bold = config.bold },
    PmenuMatchSel = { link = "PmenuMatch" },
    PmenuSel = { bg = colors.bg3, bold = config.bold },
    PmenuSbar = { bg = colors.bg2 },
    PmenuThumb = { bg = colors.bg4 },
    DiffDelete = { bg = colors.diff_delete },
    DiffAdd = { bg = colors.diff_add },
    DiffChange = { bg = colors.diff_change },
    DiffText = { bg = colors.primary_active, fg = colors.bg0 },
    SpellCap = { link = "ThemeSecondaryActiveUnderline" },
    SpellBad = { link = "ThemePrimaryUnderline" },
    SpellLocal = { link = "ThemeSecondarySoftUnderline" },
    SpellRare = { link = "ThemePrimaryMutedUnderline" },
    Whitespace = { fg = colors.bg2 },
    EndOfBuffer = { link = "NonText" },
  }
end

return M
