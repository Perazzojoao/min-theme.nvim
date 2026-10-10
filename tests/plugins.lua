local test_file = debug.getinfo(1, "S").source:sub(2)
local test_dir = vim.fn.fnamemodify(test_file, ":p:h")
local root = vim.fn.fnamemodify(test_dir, ":h")
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local colors = {
  editor_bg = "#121212",
  fg = "#cfcfcf",
  panel_bg = "#121212",
  border = "#383838",
  cursorline = "#181818",
  selection = "#2a2a2a",
  link = "#36a3ff",
  bg0 = "#121212",
  bg1 = "#1f1f1f",
  bg3 = "#383838",
  fg0 = "#c1c1c1",
  fg1 = "#cfcfcf",
  fg3 = "#888888",
  fg4 = "#727272",
  muted = "#6b737c",
  primary = "#f97583",
  primary_active = "#ff7a84",
  primary_soft = "#ffab70",
  secondary = "#b392f0",
  secondary_active = "#79b8ff",
  secondary_soft = "#9db1c5",
  warning = "#cd9731",
  info = "#79b8ff",
  success = "#9bc774",
  git_added = "#8fc07a",
  git_modified = "#d7ab73",
  git_deleted = "#ff7a84",
  tab = { fg = "#6b737c", bg = "#1a1a1a" },
  tab_selected = { fg = "#79b8ff", bg = "#121212" },
  tab_fill = { fg = "#6b737c", bg = "#1a1a1a" },
}

local config = {
  bold = true,
  underline = true,
  undercurl = true,
  italic = { strings = false, comments = false, operators = false, folds = false },
}

local snacks = require("min-theme.groups.plugins.snacks").get(colors, config)
assert(snacks.SnacksPicker.bg == colors.panel_bg)
assert(snacks.SnacksPickerBorder.bg == colors.panel_bg)
assert(snacks.SnacksPickerBorder.fg == colors.border)
assert(snacks.SnacksPickerListNormalFloat.bg == colors.panel_bg)
assert(snacks.SnacksPickerBoxNormalFloat.bg == colors.panel_bg)
assert(snacks.SnacksPickerInputNormalFloat.bg == colors.panel_bg)
assert(snacks.SnacksPickerPreview.link == "Normal")
assert(snacks.SnacksPickerPreviewNormalFloat.link == "SnacksPickerPreview")
assert(snacks.SnacksInputBorder.bg == colors.panel_bg and snacks.SnacksInputBorder.fg == colors.border)
assert(snacks.SnacksPickerListCursorLine.bg == colors.cursorline)
assert(snacks.SnacksPickerListVisual.bg == colors.selection)
assert(snacks.SnacksPickerMatch.fg == colors.primary_active)
assert(snacks.SnacksNotifierHistory.bg == colors.panel_bg)
assert(snacks.SnacksNotifierHistoryDateTime.bg == colors.panel_bg)
assert(snacks.SnacksNotifierTitleError.fg == colors.primary)

local cmp = require("min-theme.groups.plugins.cmp").get(colors, config)
assert(cmp.BlinkCmpMenu.bg == colors.panel_bg)
assert(cmp.BlinkCmpMenuBorder.fg == colors.border)
assert(cmp.BlinkCmpDoc.bg == colors.panel_bg)
assert(cmp.BlinkCmpSignatureHelp.bg == colors.panel_bg)
assert(cmp.CmpPmenu.bg == colors.panel_bg)
assert(cmp.CmpDocumentationBorder.fg == colors.border)

local markdown = require("min-theme.groups.plugins.markdown").get(colors, config)
for _, name in ipairs({
  "markdownCode",
  "markdownCodeBlock",
  "markdownCodeDelimiter",
  "@markup.raw",
  "@markup.raw.block",
}) do
  assert(markdown[name].bg == colors.panel_bg)
  assert(markdown[name].fg == nil)
end

local git = require("min-theme.groups.plugins.git").get(colors, config)
assert(git.GitSignsAdd.link == "ThemeGitAddedSign")
assert(git.GitSignsChange.link == "ThemeGitModifiedSign")
assert(git.GitSignsDelete.link == "ThemeGitDeletedSign")

local bufferline = require("min-theme.groups.plugins.bufferline").get(colors, config)
assert(bufferline.BufferLineBuffer.bg == colors.tab.bg)
assert(bufferline.BufferLineBufferSelected.bg == colors.tab_selected.bg)
assert(bufferline.BufferLineBufferSelected.fg == colors.tab_selected.fg)
assert(bufferline.BufferLineBufferSelected.bold == true)
assert(bufferline.BufferLineBufferSelected.italic == false)
assert(bufferline.BufferLineNumbersSelected.bg == colors.tab_selected.bg)
assert(bufferline.BufferLineErrorSelected.fg == colors.primary)
assert(bufferline.BufferLineErrorSelected.sp == colors.primary)
assert(bufferline.BufferLineErrorSelected.underline == nil and bufferline.BufferLineErrorSelected.undercurl == nil)
assert(
  bufferline.BufferLineErrorDiagnosticSelected.underline == nil
    and bufferline.BufferLineErrorDiagnosticSelected.undercurl == nil
)
assert(bufferline.BufferLineModifiedSelected.fg == colors.primary_soft)
assert(bufferline.BufferLineIndicatorSelected.bg == colors.tab_selected.bg)
assert(bufferline.BufferLineSeparatorSelected.fg == colors.tab_fill.bg)
assert(bufferline.BufferLineTruncMarker.bg == colors.tab_fill.bg)
assert(bufferline.BufferLineGroupLabel.bg == colors.tab_fill.bg)

config.bold = false
local without_bold = require("min-theme.groups.plugins.bufferline").get(colors, config)
assert(without_bold.BufferLineBufferSelected.bold == false)
assert(without_bold.BufferLineNumbersSelected.bold == false)

print("min-theme plugin highlight assertions passed")
