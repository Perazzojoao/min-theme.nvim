local M = {}

local api = vim.api
local retry_delays = { 20, 80, 200 }
local active = false
local generation = 0
local event_group
local patched_module
local original_set_icon_highlight
local wrapped_set_icon_highlight
local tracked_groups = {}
local tracked_order = {}

local function pack(...)
  return { n = select("#", ...), ... }
end

local function unpack_values(values)
  return unpack(values, 1, values.n)
end

local function clear_events()
  if event_group then
    pcall(api.nvim_del_augroup_by_id, event_group)
    event_group = nil
  end
end

local function reset_icon_cache(module)
  local reset = module and module.reset_icon_hl_cache
  if type(reset) == "function" then
    pcall(reset)
  end
end

local function snapshot_highlight(name)
  if tracked_groups[name] then
    return
  end

  local ok, attrs = pcall(api.nvim_get_hl, 0, { name = name, link = true })
  if not ok or type(attrs) ~= "table" then
    attrs = {}
  end
  -- `nvim_get_hl` may return this control flag for groups created with
  -- default=true; it is not a highlight attribute and would block restoration.
  attrs.default = nil
  tracked_groups[name] = vim.deepcopy(attrs)
  tracked_order[#tracked_order + 1] = name
end

local function restore_highlights()
  for index = #tracked_order, 1, -1 do
    local name = tracked_order[index]
    local attrs = tracked_groups[name]
    if attrs then
      pcall(api.nvim_set_hl, 0, name, attrs)
    end
    tracked_groups[name] = nil
    tracked_order[index] = nil
  end
end

local function visibility_values()
  local constants = package.loaded["bufferline.constants"]
  local visibility = type(constants) == "table" and constants.visibility or nil
  if type(visibility) == "table" then
    return visibility
  end
  -- Bufferline 4.9.1 exposes these values from bufferline.constants.
  return { NONE = 1, INACTIVE = 2, SELECTED = 3 }
end

local function state_suffix(state, visibility)
  if state == visibility.SELECTED then
    return "Selected"
  elseif state == visibility.INACTIVE then
    return "Inactive"
  elseif state == visibility.NONE then
    return ""
  end
end

local function parent_for_state(state, hls, visibility)
  local key
  if state == visibility.SELECTED then
    key = "buffer_selected"
  elseif state == visibility.INACTIVE then
    key = "buffer_visible"
  elseif state == visibility.NONE then
    key = "background"
  end

  local parent = key and hls[key]
  if type(parent) ~= "table" then
    if state == visibility.SELECTED then
      parent = hls.buffer or hls.background
    elseif state == visibility.INACTIVE then
      parent = hls.buffer or hls.background
    else
      parent = hls.buffer or hls.buffer_visible or hls.background
    end
  end
  if type(parent) ~= "table" then
    return nil
  end
  local fallback_group = key == "buffer_selected" and "BufferLineBufferSelected"
    or key == "buffer_visible" and "BufferLineBufferVisible"
    or "BufferLineBackground"
  return parent, fallback_group
end

local function icon_group_name(state, base_hl, visibility)
  if type(base_hl) ~= "string" then
    return nil
  end
  local suffix = state_suffix(state, visibility)
  if suffix == nil then
    return nil
  end
  return "BufferLine" .. base_hl .. suffix
end

local function set_icon_background(icon_group, parent, fallback_group)
  local parent_group = parent.hl_group or fallback_group
  if type(parent_group) ~= "string" or parent_group == "" then
    return
  end

  local parent_ok, parent_attrs = pcall(api.nvim_get_hl, 0, { name = parent_group, link = false })
  if not parent_ok or type(parent_attrs) ~= "table" then
    return
  end
  local icon_ok, icon_attrs = pcall(api.nvim_get_hl, 0, { name = icon_group, link = false })
  if not icon_ok or type(icon_attrs) ~= "table" then
    return
  end

  -- Keep the DevIcon's foreground and style, changing only its background.
  icon_attrs.default = nil
  icon_attrs.bg = parent_attrs.bg or "NONE"
  pcall(api.nvim_set_hl, 0, icon_group, icon_attrs)
end

local function loaded_api()
  local bufferline = package.loaded.bufferline
  local highlights = package.loaded["bufferline.highlights"]
  local config_module = package.loaded["bufferline.config"]
  local constants = package.loaded["bufferline.constants"]

  if type(bufferline) ~= "table" or type(highlights) ~= "table" then
    return nil, "pending"
  end
  if type(highlights.set_icon_highlight) ~= "function" then
    return nil, "pending"
  end
  if type(config_module) ~= "table" or type(config_module.get) ~= "function" then
    return nil, "pending"
  end

  local ok, config = pcall(config_module.get)
  local options = ok and type(config) == "table" and config.options or nil
  if type(options) ~= "table" then
    return nil, "pending"
  end
  if options.themable == false then
    return nil, "disabled"
  end

  local visibility = type(constants) == "table" and constants.visibility or nil
  if type(visibility) ~= "table" then
    visibility = visibility_values()
  end

  return { highlights = highlights, visibility = visibility }, "ready"
end

local function detach_patch()
  if patched_module and patched_module.set_icon_highlight == wrapped_set_icon_highlight then
    patched_module.set_icon_highlight = original_set_icon_highlight
  end
  reset_icon_cache(patched_module)
  patched_module = nil
  original_set_icon_highlight = nil
  wrapped_set_icon_highlight = nil
  restore_highlights()
end

local function try_patch()
  if not active then
    return false
  end

  local loaded, status = loaded_api()
  if status == "disabled" then
    clear_events()
    detach_patch()
    return false
  end
  if not loaded then
    return false
  end

  local highlights = loaded.highlights
  if patched_module == highlights and highlights.set_icon_highlight == wrapped_set_icon_highlight then
    clear_events()
    return true
  end

  detach_patch()
  local original = highlights.set_icon_highlight
  local visibility = loaded.visibility
  local wrapper
  wrapper = function(state, hls, base_hl, ...)
    local _, current_status = loaded_api()
    if current_status == "disabled" then
      M.disable()
      return original(state, hls, base_hl, ...)
    end
    local expected_group = icon_group_name(state, base_hl, visibility)
    if expected_group then
      snapshot_highlight(expected_group)
    end

    local result = pack(original(state, hls, base_hl, ...))
    local icon_group = result[1]
    if active and expected_group and icon_group == expected_group and type(hls) == "table" then
      local parent, fallback_group = parent_for_state(state, hls, visibility)
      if parent then
        set_icon_background(icon_group, parent, fallback_group)
      end
    end
    return unpack_values(result)
  end

  patched_module = highlights
  original_set_icon_highlight = original
  wrapped_set_icon_highlight = wrapper
  highlights.set_icon_highlight = wrapper
  reset_icon_cache(highlights)
  clear_events()
  return true
end

local function install_events()
  if event_group or not active then
    return
  end

  event_group = api.nvim_create_augroup("MinThemeBufferlineIntegration", { clear = true })
  api.nvim_create_autocmd({ "VimEnter", "ColorScheme", "BufWinEnter" }, {
    group = event_group,
    callback = function()
      if active and not try_patch() then
        vim.schedule(try_patch)
      end
    end,
  })
  api.nvim_create_autocmd("User", {
    group = event_group,
    pattern = "VeryLazy",
    callback = function()
      if active and not try_patch() then
        vim.schedule(try_patch)
      end
    end,
  })
end

local function schedule_bounded_retries(token)
  for _, delay in ipairs(retry_delays) do
    vim.defer_fn(function()
      if active and generation == token then
        try_patch()
      end
    end, delay)
  end
end

---Enable the Bufferline icon background adapter after the theme groups load.
---@param config table? Theme config supplied by min-theme
function M.enable(config)
  active = true
  generation = generation + 1
  local token = generation
  if try_patch() then
    reset_icon_cache(patched_module)
  else
    install_events()
    schedule_bounded_retries(token)
  end
end

---Restore Bufferline's original icon highlight function and touched groups.
function M.disable()
  active = false
  generation = generation + 1
  clear_events()
  detach_patch()
end

return M
