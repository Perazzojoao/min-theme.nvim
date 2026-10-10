local test_file = debug.getinfo(1, "S").source:sub(2)
local test_dir = vim.fn.fnamemodify(test_file, ":p:h")
local root = vim.fn.fnamemodify(test_dir, ":h")
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local adapter = require("min-theme.integrations.bufferline")
local visibility = { NONE = 1, INACTIVE = 2, SELECTED = 3 }
local config = { options = { themable = true } }
local reset_count = 0

local function icon_name(state, base)
  local suffix = state == visibility.SELECTED and "Selected" or state == visibility.INACTIVE and "Inactive" or ""
  return "BufferLine" .. base .. suffix
end

local function original_set_icon_highlight(state, hls, base)
  local name = icon_name(state, base)
  vim.api.nvim_set_hl(0, name, {
    fg = "#abcdef",
    bg = "#777777",
    italic = true,
    bold = true,
    underline = true,
  })
  return name
end

local highlights = {
  set_icon_highlight = original_set_icon_highlight,
  reset_icon_hl_cache = function()
    reset_count = reset_count + 1
  end,
}

local function load_fake_plugin()
  package.loaded.bufferline = {}
  package.loaded["bufferline.highlights"] = highlights
  package.loaded["bufferline.config"] = {
    get = function()
      return config
    end,
  }
  package.loaded["bufferline.constants"] = { visibility = visibility }
end

local function get_hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local function color_hex(color)
  if type(color) == "number" then
    return ("#%06x"):format(color)
  end
  return color
end

vim.api.nvim_set_hl(0, "MinThemeBufferlineSelected", { fg = "#79b8ff", bg = "#121212" })
vim.api.nvim_set_hl(0, "MinThemeBufferlineVisible", { fg = "#6b737c", bg = "#1a1a1a" })
vim.api.nvim_set_hl(0, "MinThemeBufferlineBackground", { fg = "#6b737c", bg = "#1a1a1a" })

load_fake_plugin()
local before = vim.deepcopy(config)
adapter.enable({})
local wrapper = highlights.set_icon_highlight
assert(wrapper ~= original_set_icon_highlight, "loaded Bufferline API was not wrapped")
adapter.enable({})
assert(highlights.set_icon_highlight == wrapper, "repeated enable wrapped the adapter twice")
assert(vim.deep_equal(config, before), "adapter changed the user's Bufferline configuration")

local hls = {
  buffer_selected = { hl_group = "MinThemeBufferlineSelected" },
  buffer_visible = { hl_group = "MinThemeBufferlineVisible" },
  background = { hl_group = "MinThemeBufferlineBackground" },
}

for _, state in ipairs({ visibility.SELECTED, visibility.INACTIVE, visibility.NONE }) do
  local name = highlights.set_icon_highlight(state, hls, "DevIconLua")
  local actual = get_hl(name)
  local expected_bg = state == visibility.SELECTED and "#121212"
    or state == visibility.INACTIVE and "#1a1a1a"
    or "#1a1a1a"
  assert(color_hex(actual.bg) == expected_bg, "icon background did not follow its final parent group")
  assert(color_hex(actual.fg) == "#abcdef", "DevIcon foreground was changed")
  assert(actual.italic == true and actual.bold == true and actual.underline == true, "DevIcon styles were changed")
end

adapter.disable()
assert(highlights.set_icon_highlight == original_set_icon_highlight, "disable did not restore the original API")
assert(reset_count >= 3, "icon highlight cache was not cleared on activation and cleanup")
assert(vim.tbl_isempty(get_hl("BufferLineDevIconLuaSelected")), "disable left the selected icon highlight behind")

-- The adapter waits for lazy-loaded Bufferline without requiring it itself.
package.loaded.bufferline = nil
package.loaded["bufferline.highlights"] = nil
package.loaded["bufferline.config"] = nil
package.loaded["bufferline.constants"] = nil
package.preload.bufferline = function()
  error("adapter must not load Bufferline")
end
adapter.enable({})
assert(package.loaded.bufferline == nil, "enable forced Bufferline to load")
load_fake_plugin()
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
assert(highlights.set_icon_highlight ~= original_set_icon_highlight, "lazy-loaded Bufferline was not attached")
adapter.disable()
package.preload.bufferline = nil

-- Respect Bufferline's explicit opt-out.
config.options.themable = false
load_fake_plugin()
adapter.enable({})
assert(highlights.set_icon_highlight == original_set_icon_highlight, "themable=false was ignored")
adapter.disable()
config.options.themable = true

-- Changing the plugin opt-out after attaching must also stop background fixes.
adapter.enable({})
config.options.themable = false
local name = highlights.set_icon_highlight(visibility.SELECTED, hls, "DevIconRuntimeOptOut")
assert(highlights.set_icon_highlight == original_set_icon_highlight, "runtime opt-out left the wrapper installed")
assert(get_hl(name).bg == 0x777777, "runtime opt-out still changed the icon background")
config.options.themable = true
adapter.disable()

print("min-theme Bufferline adapter assertions passed")
