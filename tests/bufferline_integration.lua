-- Run from the checkout; BUFFERLINE_RTP optionally selects the real plugin checkout.
local test_file = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(test_file, ":p:h:h")
vim.opt.runtimepath:prepend(root)
local plugin_root = vim.env.BUFFERLINE_RTP
if not plugin_root or plugin_root == "" then
  plugin_root = vim.fn.stdpath("data") .. "/site/pack/core/opt/bufferline.nvim"
end
if vim.fn.filereadable(plugin_root .. "/lua/bufferline.lua") ~= 1 then
  print("SKIP: Bufferline is not installed; set BUFFERLINE_RTP to its checkout")
  vim.cmd("qa!")
  return
end
vim.opt.runtimepath:prepend(plugin_root)

local theme = require("min-theme")
theme.setup({ variable_roles = false })
vim.cmd.colorscheme("min-theme")
assert(not package.loaded.bufferline, "theme force-loaded Bufferline before plugin setup")

local highlights = require("bufferline.highlights")
local original = highlights.set_icon_highlight
require("bufferline").setup({
  options = { themable = true, color_icons = true, separator_style = "slant", always_show_bufferline = true },
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
local config_module = require("bufferline.config")
local visibility = require("bufferline.constants").visibility
local states = {
  { value = visibility.SELECTED, key = "buffer_selected", parent = "TabLineSel" },
  { value = visibility.INACTIVE, key = "buffer_visible", parent = "TabLine" },
  { value = visibility.NONE, key = "background", parent = "TabLine" },
}
local icon_base = "MinThemeIntegrationDevIcon"
local function hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end
local function check_icons()
  assert(highlights.set_icon_highlight == original, "theme replaced Bufferline's native icon function")
  vim.api.nvim_set_hl(0, icon_base, { fg = "#abcdef", bold = true })
  local config = config_module.get()
  for _, state in ipairs(states) do
    local parent = config.highlights[state.key]
    local expected = hl(state.parent).bg
    assert(hl(parent.hl_group).bg == expected, "static tab background does not match theme parent")
    local name = highlights.set_icon_highlight(state.value, config.highlights, icon_base)
    local actual = hl(name)
    assert(actual.bg == expected, "native icon background did not follow the public reference")
    assert(actual.fg == 0xabcdef, "DevIcon foreground changed")
    assert(not actual.bold and not actual.italic, "native icon styles changed")
  end
end
check_icons()
assert(hl("BufferLineBackground").bg == 0x1a1a1a)
assert(hl("BufferLineBufferSelected").bg == 0x121212)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(250)
check_icons()
vim.cmd.colorscheme("min-theme")
check_icons()

-- Distinct fill and tab colors ensure icons follow their tabs, not the empty bar.
theme.setup({
  variable_roles = false,
  overrides = {
    TabLine = { bg = "#232323" },
    TabLineSel = { bg = "#151515" },
    TabLineFill = { bg = "#292929" },
  },
})
vim.cmd.colorscheme("min-theme")
check_icons()
assert(hl("BufferLineBackground").bg == 0x232323)
assert(hl("BufferLineFill").bg == 0x292929)
assert(hl("BufferLineBufferSelected").bg == 0x151515)
assert(hl("Normal").bg == 0x121212, "tab color changes affected the editor")

vim.cmd.colorscheme("default")
assert(highlights.set_icon_highlight == original, "theme switch replaced Bufferline's native icon function")
theme.setup({ variable_roles = false })
vim.cmd.colorscheme("min-theme")
check_icons()
assert(not package.loaded["min-theme.integrations.bufferline"], "removed adapter was loaded")
assert(vim.v.errmsg == "", "unexpected startup error: " .. vim.v.errmsg)
print("PASS native Bufferline icon references, lazy load, reload, overrides and theme switch")
vim.cmd.qa()
