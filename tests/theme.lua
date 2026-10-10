-- Run from the checkout: nvim --headless -u NONE -i NONE -l tests/theme.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local theme = require("min-theme")
local function hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end
local function eq(expected, actual, label)
  assert(vim.deep_equal(expected, actual), label .. ": " .. vim.inspect(actual))
end
local function load(options)
  theme.setup(options)
  vim.cmd.colorscheme("min-theme")
end

load()
eq(0x121212, hl("Normal").bg, "editor background")
eq(0xcfcfcf, hl("Normal").fg, "editor foreground")
eq(0x121212, hl("NormalFloat").bg, "float background")
eq(0x181818, hl("CursorLine").bg, "current row")
eq(0x2a2a2a, hl("Visual").bg, "selection background")
assert(not hl("Visual").fg and not hl("Visual").reverse, "selection must preserve syntax")
assert(hl("LspSignatureActiveParameter").bold and hl("LspSignatureActiveParameter").italic)
assert(not hl("LspSignatureActiveParameter").fg and not hl("LspSignatureActiveParameter").bg)
assert(not hl("RenderMarkdownCode").fg and hl("RenderMarkdownCode").bg == 0x121212)
for _, name in ipairs({
  "DiagnosticSignError",
  "DiagnosticSignWarn",
  "DiagnosticSignInfo",
  "DiagnosticSignHint",
  "GitSignsAdd",
  "GitSignsChange",
  "GitSignsDelete",
}) do
  eq(0x121212, hl(name).bg, name)
  assert(hl(name).fg, "missing sign severity color " .. name)
end
for _, name in ipairs({
  "@variable",
  "Identifier",
  "@lsp.type.variable",
  "@lsp.typemod.variable.declaration",
  "@lsp.typemod.property.definition",
}) do
  eq(0x79b8ff, hl(name).fg, "uniform fallback " .. name)
end
for _, name in ipairs({ "@variable.parameter", "@parameter", "@lsp.type.parameter" }) do
  eq(0xff9800, hl(name).fg, "parameter " .. name)
end
for _, name in ipairs({ "String", "htmlTagName", "xmlTagName" }) do
  eq(0xffab70, hl(name).fg, name)
end
for _, name in ipairs({ "Delimiter", "@tag.delimiter.html", "@tag.delimiter.xml" }) do
  eq(0xbbbbbb, hl(name).fg, name)
end
assert(not package.loaded.bufferline and not package.loaded.snacks and not package.loaded.blink)

local options =
  { overrides = { DiagnosticSignError = { italic = true }, Normal = { bg = "#101010" }, Comment = { bold = true } } }
local before = vim.deepcopy(options)
load(options)
eq(before, options, "setup does not mutate caller options")
eq(0xf97583, hl("DiagnosticSignError").fg, "partial override preserves linked foreground")
eq(0x121212, hl("DiagnosticSignError").bg, "partial override preserves linked background")
assert(hl("DiagnosticSignError").italic)
eq(0xcfcfcf, hl("Normal").fg, "partial normal override preserves foreground")
eq(0x101010, hl("Normal").bg, "partial normal override background")
eq(0x6b737c, hl("Comment").fg, "partial syntax override preserves foreground")
load({ overrides = { DiagnosticSignError = { link = "String" } } })
eq(0xffab70, hl("DiagnosticSignError").fg, "explicit link replacement")
load({ transparent_mode = true, italic = { strings = true, comments = true } })
assert(not hl("Normal").bg and not hl("DiagnosticSignError").bg)
assert(hl("String").italic and hl("Comment").italic)
load({
  variable_roles = false,
  integrations = {
    lsp = false,
    treesitter = false,
    bufferline = false,
    snacks = false,
    blink = false,
    gitsigns = false,
    render_markdown = false,
  },
})
eq(0x79b8ff, hl("@lsp.typemod.variable.declaration").fg, "disabled fallback")
eq(0xff9800, hl("@lsp.type.parameter").fg, "disabled parameter fallback")
assert(next(hl("BufferLineBufferSelected")) == nil, "disabled bufferline groups")

load()
local audit = require("min-theme.vscode").audit(
  require("min-theme.defaults").get(require("min-theme.colors").get(theme.palette, theme.config))
)
eq(105, #audit, "audited source coverage")
local autocommands = #vim.api.nvim_get_autocmds({ group = "MinThemeIntegrations" })
load()
eq(autocommands, #vim.api.nvim_get_autocmds({ group = "MinThemeIntegrations" }), "idempotent integration callbacks")
vim.cmd.colorscheme("default")
assert(not pcall(vim.api.nvim_get_autocmds, { group = "MinThemeIntegrations" }), "theme switch removes callbacks")
eq("", vim.v.errmsg, "startup errors")
print("PASS theme defaults, partial overrides, optional providers, audit and lifecycle")
vim.cmd.qa()
