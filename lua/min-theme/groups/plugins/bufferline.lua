local M = {}

local function pascal(name)
  return (name
    :gsub("_(.)", function(char)
      return char:upper()
    end)
    :gsub("^%l", string.upper))
end

local function tab_attrs(tab, fallback)
  tab = tab or fallback or {}
  return {
    fg = tab.fg,
    bg = tab.bg,
  }
end

---@param colors table
---@param config ThemeConfig
---@return table<string, HighlightDefinition>
function M.get(colors, config)
  local inactive = colors.tab or { fg = colors.fg, bg = colors.panel_bg }
  local selected = colors.tab_selected or inactive
  local fill = colors.tab_fill or inactive
  local selected_bold = config.bold ~= false
  local diagnostics = colors.diagnostics or {}
  local severity = {
    hint = diagnostics.hint or colors.secondary_soft,
    info = diagnostics.info or colors.info,
    warning = diagnostics.warning or colors.warning,
    error = diagnostics.error or colors.primary,
  }
  local groups = {}

  local function put(name, attrs)
    groups["BufferLine" .. pascal(name)] = attrs
  end

  put("fill", tab_attrs(fill, inactive))
  put("background", tab_attrs(inactive, inactive))
  put("buffer", tab_attrs(inactive, inactive))
  put("buffer_visible", tab_attrs(inactive, inactive))
  put(
    "buffer_selected",
    vim.tbl_extend("force", tab_attrs(selected, inactive), { bold = selected_bold, italic = false })
  )
  put("tab", tab_attrs(inactive, inactive))
  put("tab_selected", tab_attrs(selected, inactive))
  put("tab_close", tab_attrs(inactive, inactive))

  local state_suffixes = {
    { suffix = "", selected = false },
    { suffix = "_visible", selected = false },
    { suffix = "_selected", selected = true },
  }
  local themed_names = {
    "buffer",
    "numbers",
    "close_button",
    "hint",
    "info",
    "warning",
    "error",
    "diagnostic",
    "hint_diagnostic",
    "info_diagnostic",
    "warning_diagnostic",
    "error_diagnostic",
    "modified",
    "duplicate",
    "pick",
  }

  for _, name in ipairs(themed_names) do
    for _, state in ipairs(state_suffixes) do
      local tab = state.selected and selected or inactive
      local key = name .. state.suffix
      if name == "buffer" and state.suffix == "" then
        key = "background"
      end

      local attrs = tab_attrs(tab, inactive)
      attrs.bold = state.selected and selected_bold
      attrs.italic = false

      -- The current Bufferline setup keeps diagnostic error names red while
      -- the rest of the text follows the selected or visible tab foreground.
      if name == "error" then
        attrs.fg = severity.error
        attrs.sp = severity.error
      elseif name == "modified" then
        attrs.fg = colors.primary_soft
      elseif
        name == "hint_diagnostic"
        or name == "info_diagnostic"
        or name == "warning_diagnostic"
        or name == "error_diagnostic"
      then
        if state.selected then
          local kind = name:gsub("_diagnostic$", "")
          attrs.fg = severity[kind]
          attrs.sp = severity[kind]
        end
      end

      put(key, attrs)
    end
  end

  -- The plugin uses separate visible/selected indicator groups only.
  put("indicator_visible", { fg = inactive.fg, bg = inactive.bg, italic = false })
  put("indicator_selected", { fg = selected.fg, bg = selected.bg, bold = selected_bold, italic = false })

  for _, state in ipairs(state_suffixes) do
    local tab = state.selected and selected or inactive
    local attrs = {
      fg = fill.bg,
      bg = tab.bg,
      bold = state.selected and selected_bold,
      italic = false,
    }
    put("separator" .. state.suffix, vim.deepcopy(attrs))
    put("tab_separator" .. state.suffix, vim.deepcopy(attrs))
  end

  put("group_label", { fg = inactive.fg, bg = fill.bg, bold = selected_bold, italic = false })
  put("group_separator", { fg = fill.bg, bg = fill.bg })

  local fill_background = fill.bg or colors.editor_bg or colors.bg0
  for _, name in ipairs({ "trunc_marker", "offset_separator", "group_separator" }) do
    put(name, { bg = fill_background })
  end

  return groups
end

return M
