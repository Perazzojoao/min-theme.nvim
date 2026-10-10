---@class MinTheme
---@field config ThemeConfig
---@field palette ThemePalette
local MinTheme = {}

local default_config = require("min-theme.config").default
local palette = require("min-theme.palette")
local colors_mod = require("min-theme.colors")
local groups_mod = require("min-theme.groups")

MinTheme.config = vim.deepcopy(default_config)
MinTheme.palette = palette

---@param config ThemeConfig?
MinTheme.setup = function(config)
  MinTheme.config = vim.deepcopy(default_config)
  MinTheme.config = vim.tbl_deep_extend("force", MinTheme.config, config or {})
end

--- main load function
MinTheme.load = function()
  if vim.fn.has("nvim-0.10") == 0 then
    vim.notify_once("min-theme: you must use neovim 0.10 or higher")
    return
  end

  require("min-theme.integrations").disable()

  -- reset colors
  if vim.g.colors_name then
    vim.cmd.hi("clear")
  end
  vim.g.colors_name = "min-theme"
  vim.o.termguicolors = true
  vim.o.background = "dark"

  local colors = colors_mod.get(MinTheme.palette, MinTheme.config)

  if MinTheme.config.terminal_colors then
    colors_mod.setup_terminal_colors(colors)
  end

  local groups = groups_mod.get(colors, MinTheme.config)

  -- add highlights
  for group, settings in pairs(groups) do
    vim.api.nvim_set_hl(0, group, settings)
  end
  require("min-theme.integrations").enable(MinTheme.config)
end

return MinTheme
