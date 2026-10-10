local M = {}

---@alias Contrast "hard" | "soft" | ""

---@class ItalicConfig
---@field strings boolean
---@field comments boolean
---@field operators boolean
---@field folds boolean
---@field emphasis boolean

---@class HighlightDefinition
---@field fg string?
---@field bg string?
---@field sp string?
---@field blend integer?
---@field bold boolean?
---@field standout boolean?
---@field underline boolean?
---@field undercurl boolean?
---@field underdouble boolean?
---@field underdotted boolean?
---@field strikethrough boolean?
---@field italic boolean?
---@field reverse boolean?
---@field nocombine boolean?

---@class ThemeConfig
---@field variable_roles boolean?
---@field integrations table<string, boolean>?
---@field bold boolean?
---@field contrast Contrast?
---@field dim_inactive boolean?
---@field inverse boolean?
---@field invert_selection boolean?
---@field invert_signs boolean?
---@field invert_tabline boolean?
---@field italic ItalicConfig?
---@field overrides table<string, HighlightDefinition>?
---@field strikethrough boolean?
---@field terminal_colors boolean?
---@field transparent_mode boolean?
---@field undercurl boolean?
---@field underline boolean?
M.default = {
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
  terminal_colors = true,
  undercurl = true,
  underline = true,
  bold = true,
  italic = {
    strings = false,
    emphasis = true,
    comments = false,
    operators = false,
    folds = true,
  },
  strikethrough = true,
  invert_selection = false,
  invert_signs = false,
  invert_tabline = false,
  inverse = true,
  contrast = "",
  overrides = {},
  dim_inactive = false,
  transparent_mode = false,
}

return M
