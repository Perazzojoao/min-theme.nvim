local test_file = debug.getinfo(1, "S").source:sub(2)
local test_dir = vim.fn.fnamemodify(test_file, ":p:h")
local root = vim.fn.fnamemodify(test_dir, ":h")
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

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

local function clear_bufferline_modules()
  for name in pairs(package.loaded) do
    if name == "bufferline" or name:match("^bufferline%.") then
      package.loaded[name] = nil
    end
  end
end

clear_bufferline_modules()
local adapter = require("min-theme.integrations.bufferline")
adapter.enable({})
assert(package.loaded.bufferline == nil, "adapter force-loaded Bufferline before the lazy plugin did")

local bufferline = require("bufferline")
local user_config = {
  options = { themable = true, color_icons = true, always_show_bufferline = true },
  highlights = {},
}
bufferline.setup(user_config)
local user_config_after_setup = vim.deepcopy(user_config)
local config_module = require("bufferline.config")
local highlights = require("bufferline.highlights")
local original = highlights.set_icon_highlight

local visibility = require("bufferline.constants").visibility
local states = {
  { value = visibility.SELECTED, suffix = "Selected", parent = "BufferLineBufferSelected" },
  { value = visibility.INACTIVE, suffix = "Inactive", parent = "BufferLineBufferVisible" },
  { value = visibility.NONE, suffix = "", parent = "BufferLineBackground" },
}
local icon_base = "MinThemeIntegrationDevIcon"
local icon_hl = "BufferLine" .. icon_base
local parents = {
  buffer_selected = "BufferLineBufferSelected",
  buffer_visible = "BufferLineBufferVisible",
  background = "BufferLineBackground",
}

local function color_hex(value)
  if type(value) == "number" then
    return ("#%06x"):format(value)
  end
  return value
end

local function set_theme(theme)
  vim.api.nvim_set_hl(0, "MinThemeIntegrationDevIcon", { fg = "#abcdef", bold = true })
  for _, state in ipairs(states) do
    local color = theme[state.suffix]
    vim.api.nvim_set_hl(0, state.parent, { fg = "#cfcfcf", bg = color, bold = state.value == visibility.SELECTED })
  end
end

local function parent_refs()
  local result = {}
  for key, name in pairs(parents) do
    local attrs = vim.api.nvim_get_hl(0, { name = name, link = false })
    attrs.hl_group = name
    result[key] = attrs
  end
  return result
end

local function check_icon_states(theme)
  local hls = parent_refs()
  for _, state in ipairs(states) do
    local name = highlights.set_icon_highlight(state.value, hls, icon_base)
    assert(name == icon_hl .. state.suffix, "unexpected Bufferline icon group for visibility state")
    local actual = vim.api.nvim_get_hl(0, { name = name, link = false })
    assert(color_hex(actual.bg) == theme[state.suffix], "icon background did not follow the final parent group")
    assert(color_hex(actual.fg) == "#abcdef", "DevIcon foreground changed")
    assert(not actual.bold and not actual.italic, "Bufferline changed the icon styles unexpectedly")
  end
end

local function wait_for_wrapper(module, expected_original)
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
  local patched = vim.wait(300, function()
    return module.set_icon_highlight ~= expected_original
  end, 10)
  assert(patched, "late-loaded Bufferline API was not wrapped")
end

local first_theme = { Selected = "#121212", Inactive = "#1a1a1a", [""] = "#161616" }
set_theme(first_theme)
wait_for_wrapper(highlights, original)
assert(vim.deep_equal(user_config, user_config_after_setup), "adapter mutated Bufferline's user configuration")
assert(config_module.get().options.themable == true, "integration changed Bufferline's themable option")
check_icon_states(first_theme)

-- Disabling is what the theme manager does before another colorscheme takes over.
local first_wrapper = highlights.set_icon_highlight
adapter.disable()
assert(highlights.set_icon_highlight == original, "theme disable did not restore Bufferline's API")
for _, state in ipairs(states) do
  assert(
    vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = icon_hl .. state.suffix, link = false })),
    "theme disable left a generated icon highlight behind"
  )
end

local second_theme = { Selected = "#202020", Inactive = "#303030", [""] = "#404040" }
set_theme(second_theme)
adapter.enable({})
assert(highlights.set_icon_highlight ~= original, "theme re-enable did not wrap Bufferline's API")
assert(highlights.set_icon_highlight ~= first_wrapper, "theme re-enable reused a stale wrapper")
check_icon_states(second_theme)

adapter.disable()
assert(highlights.set_icon_highlight == original, "second theme disable did not restore Bufferline's API")

-- Requiring Bufferline's highlight module again models a plugin reload. The new
-- module table must be wrapped independently while the old table stays restored.
package.loaded["bufferline.highlights"] = nil
local reloaded_highlights = require("bufferline.highlights")
assert(reloaded_highlights ~= highlights, "Bufferline highlight module did not reload")
local reloaded_original = reloaded_highlights.set_icon_highlight
adapter.enable({})
assert(reloaded_highlights.set_icon_highlight ~= reloaded_original, "reloaded Bufferline API was not wrapped")
assert(highlights.set_icon_highlight == original, "reload left the previous Bufferline API wrapped")
check_icon_states(second_theme)
assert(vim.deep_equal(user_config, user_config_after_setup), "reload path mutated Bufferline's user configuration")

adapter.disable()
assert(reloaded_highlights.set_icon_highlight == reloaded_original, "disable did not restore the reloaded API")
assert(vim.deep_equal(user_config, user_config_after_setup), "cleanup changed Bufferline's user configuration")

print("min-theme installed Bufferline icon integration assertions passed")
