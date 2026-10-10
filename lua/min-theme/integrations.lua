local M = {}
local group
local active = {}

local function stop(name)
  local mod = active[name]
  if mod then
    pcall(mod.disable)
    active[name] = nil
  end
end

function M.disable()
  for name in pairs(active) do
    stop(name)
  end
  if group then
    pcall(vim.api.nvim_del_augroup_by_id, group)
    group = nil
  end
end

function M.enable(config)
  M.disable()
  group = vim.api.nvim_create_augroup("MinThemeIntegrations", { clear = true })
  vim.api.nvim_create_autocmd("ColorSchemePre", {
    group = group,
    callback = function()
      M.disable()
    end,
  })
  for _, name in ipairs({ "roles", "bufferline" }) do
    if name ~= "bufferline" or config.integrations.bufferline then
      local ok, mod = pcall(require, "min-theme.integrations." .. name)
      if ok then
        local enabled, err = pcall(mod.enable, config)
        if enabled then
          active[name] = mod
        else
          pcall(mod.disable)
          vim.notify_once("min-theme: " .. name .. " integration unavailable: " .. tostring(err), vim.log.levels.WARN)
        end
      else
        vim.notify_once("min-theme: " .. name .. " integration unavailable: " .. tostring(mod), vim.log.levels.WARN)
      end
    end
  end
  -- Vim's HTML syntax places tag names and delimiters in the same region.
  -- Add a contained name match without replacing the user's syntax queries.
  local function html_names(buf)
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "html" and vim.bo[buf].syntax ~= "" then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd([[syntax match MinThemeHtmlTagName /\%(<\/\?\s*\)\@<=[[:alnum:]_:-]\+/ contained containedin=htmlTagN]])
      end)
    end
  end
  vim.api.nvim_create_autocmd("Syntax", {
    group = group,
    pattern = "html",
    callback = function(event)
      vim.schedule(function()
        if group and vim.g.colors_name == "min-theme" then
          pcall(html_names, event.buf)
        end
      end)
    end,
  })
  -- Clear our optional syntax match on switch without clearing any native group.
  active.html = {
    disable = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "html" then
          pcall(vim.api.nvim_buf_call, buf, function()
            vim.cmd("silent! syntax clear MinThemeHtmlTagName")
          end)
        end
      end
    end,
  }
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    pcall(html_names, buf)
  end
end

return M
