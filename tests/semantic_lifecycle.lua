-- Run: nvim --headless -u NONE -i NONE -l tests/semantic_lifecycle.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/site")
local api = vim.api
local semantic = vim.lsp.semantic_tokens
local theme = require("min-theme")
local roles = require("min-theme.integrations.roles")
vim.cmd.colorscheme("min-theme")
local buf = api.nvim_get_current_buf()
api.nvim_buf_set_name(buf, vim.fn.tempname() .. ".js")
api.nvim_buf_set_lines(buf, 0, -1, false, {
  "let v = 1;",
  "use(v);",
  "external.go(v);",
  "// typing",
  "function f(p) { return p; }",
})
vim.bo[buf].filetype = "javascript"
local parser_ok, parser = pcall(vim.treesitter.get_parser, buf, "javascript")
assert(parser_ok and parser, "required test parser unavailable: javascript")

local kinds = { v = 0, external = 0, go = 1, p = 2 }
local responses, document = {}, ""
local function encode_tokens()
  local data, previous_row, previous_col = {}, 0, 0
  for row, line in ipairs(vim.split(document, "\n", { plain = true })) do
    for offset, word in line:gmatch("()([%a_][%w_]*)") do
      local kind = kinds[word]
      if kind then
        local r, col = row - 1, offset - 1
        local delta_row = r - previous_row
        vim.list_extend(data, {
          delta_row,
          delta_row == 0 and col - previous_col or col,
          #word,
          kind,
          kind == 0 and line:match("^let v") and word == "v" and 1 or 0,
        })
        previous_row, previous_col = r, col
      end
    end
  end
  return { data = data }
end

local function start(name)
  return assert(vim.lsp.start({
    name = name,
    flags = { debounce_text_changes = 0 },
    on_attach = function(client, buffer)
      if semantic.enable then
        semantic.enable(true, { bufnr = buffer })
      else
        semantic.start(buffer, client.id)
      end
    end,
    cmd = function(dispatchers)
      local sequence, closed = 0, false
      return {
        request = function(method, _, callback, done)
          sequence = sequence + 1
          local request_id, result = sequence, vim.NIL
          if method == "initialize" then
            result = {
              capabilities = {
                positionEncoding = "utf-16",
                textDocumentSync = 1,
                semanticTokensProvider = {
                  legend = { tokenTypes = { "variable", "method", "parameter" }, tokenModifiers = { "declaration" } },
                  full = true,
                },
              },
            }
          elseif method == "textDocument/semanticTokens/full" then
            result = encode_tokens()
          end
          vim.defer_fn(function()
            if method == "textDocument/semanticTokens/full" then
              responses[name] = (responses[name] or 0) + 1
            end
            if done then
              done(request_id)
            end
            callback(nil, result, request_id)
          end, method == "textDocument/semanticTokens/full" and 50 or 0)
          return true, request_id
        end,
        notify = function(method, params)
          if method == "textDocument/didOpen" then
            document = params.textDocument.text
          elseif method == "textDocument/didChange" then
            document = params.contentChanges[1].text
          end
          return true
        end,
        is_closing = function()
          return closed
        end,
        terminate = function()
          closed = true
          dispatchers.on_exit(0, 0)
        end,
      }
    end,
  }))
end

-- Only the test drives the native decoration provider explicitly in headless mode.
local function state(id)
  local engine = semantic.__STHighlighter.active[buf]
  if engine then
    engine:on_win(0, api.nvim_buf_line_count(buf))
    return engine.client_state[id]
  end
end
local function settled(id)
  assert(
    vim.wait(1500, function()
      local current = state(id)
      return current
        and current.current_result.highlights
        and current.current_result.version == vim.lsp.util.buf_versions[buf]
    end, 5),
    "native semantic response did not settle"
  )
end
local function namespaces(id)
  local result = { assert(state(id)).namespace }
  local legacy = api.nvim_get_namespaces()["min-theme.lsp-roles." .. id]
  if legacy then
    result[#result + 1] = legacy
  end
  return result
end
local function marks(id)
  local result = {}
  for _, ns in ipairs(namespaces(id)) do
    vim.list_extend(result, api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true }))
  end
  return result
end
local function role(id, row, col)
  for _, mark in ipairs(marks(id)) do
    if mark[2] == row and mark[3] == col and mark[4].hl_group:match("^@variable%.") then
      return mark[4].hl_group
    end
  end
end
local function custom_count(id)
  local count = 0
  for _, mark in ipairs(marks(id)) do
    if mark[4].hl_group:match("^@variable%.") then
      count = count + 1
    end
  end
  return count
end
local function assert_color(id, row, col, expected)
  local winner, priority
  local highlight_namespaces = namespaces(id)
  highlight_namespaces[#highlight_namespaces + 1] = roles._namespace
  for _, ns in ipairs(highlight_namespaces) do
    for _, mark in ipairs(api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
      local details = mark[4]
      if mark[2] == row and mark[3] <= col and details.end_row == row and details.end_col > col then
        local fg = api.nvim_get_hl(0, { name = details.hl_group, link = false }).fg
        if fg and (not priority or details.priority > priority) then
          winner, priority = fg, details.priority
        end
      end
    end
  end
  assert(winner == expected, "unexpected rendered foreground: " .. vim.inspect({ row, col, winner, expected }))
end
local function type_comment()
  local line = api.nvim_buf_get_lines(buf, 3, 4, false)[1]
  api.nvim_buf_set_text(buf, 3, #line, 3, #line, { "a" })
end

-- A second token consumer must be restored when the theme requests native cleanup.
api.nvim_set_hl(0, "MinThemeTestOther", { bold = true })
api.nvim_create_autocmd("LspTokenUpdate", {
  callback = function(ev)
    if ev.data.token.type == "method" then
      semantic.highlight_token(ev.data.token, ev.buf, ev.data.client_id, "MinThemeTestOther")
    end
  end,
})
local id = start("min-theme-semantic-test")
settled(id)
assert(custom_count(id) == 6, "initial semantic roles missing")
assert_color(id, 0, 4, 0xcfcfcf)
assert_color(id, 1, 4, 0xcfcfcf)
assert_color(id, 2, 0, 0x79b8ff)
assert_color(id, 4, 11, 0xff9800)
local before = responses["min-theme-semantic-test"]
for _ = 1, 6 do
  local syntax_count = #api.nvim_buf_get_extmarks(buf, roles._namespace, 0, -1, {})
  type_comment()
  assert(#api.nvim_buf_get_extmarks(buf, roles._namespace, 0, -1, {}) == syntax_count, "syntax roles blinked")
  assert_color(id, 0, 4, 0xcfcfcf)
  assert_color(id, 1, 4, 0xcfcfcf)
  assert_color(id, 2, 0, 0x79b8ff)
  assert_color(id, 4, 11, 0xff9800)
  vim.wait(60, function()
    return false
  end, 5)
  assert(responses["min-theme-semantic-test"] == before, "debounce expired during continuous typing")
  assert_color(id, 1, 4, 0xcfcfcf)
end
settled(id)
assert(custom_count(id) == 6, "semantic snapshot accumulated duplicate roles")

-- A newly received non-variable category must replace the prior role at the same position.
kinds.v = 1
type_comment()
settled(id)
assert(not role(id, 0, 4) and not role(id, 1, 4), "old variable role survived a category change")
kinds.v = 0
type_comment()
settled(id)

api.nvim_buf_set_lines(buf, 1, 2, false, { "use(1);" })
settled(id)
assert(not role(id, 1, 4), "removed variable retained a semantic role")
api.nvim_buf_set_lines(buf, 0, 0, false, { "// heading" })
assert_color(id, 1, 4, 0xcfcfcf)
settled(id)
assert(role(id, 1, 4) == "@variable.declaration" and not role(id, 0, 4), "roles did not follow inserted lines")
api.nvim_buf_set_lines(buf, 2, 3, false, { "v.go();" })
settled(id)
assert(role(id, 2, 0) == "@variable.access", "standalone-to-receiver classification did not update")

vim.cmd.colorscheme("min-theme")
settled(id)
assert(custom_count(id) == 6, "theme reload duplicated or lost roles")
roles.disable()
assert(custom_count(id) == 0, "disable retained theme semantic overrides")
settled(id)
assert(custom_count(id) == 0 and #marks(id) > 0, "disable did not restore native tokens")
local other = false
for _, mark in ipairs(marks(id)) do
  other = other or mark[4].hl_group == "MinThemeTestOther"
end
assert(other, "disable did not restore another token consumer")

theme.setup({ variable_roles = false })
vim.cmd.colorscheme("min-theme")
settled(id)
assert(not role(id, 1, 4) and role(id, 5, 11) == "@variable.parameter", "disabled variable roles changed parameters")
theme.setup({ integrations = { lsp = false } })
vim.cmd.colorscheme("min-theme")
settled(id)
assert(custom_count(id) == 0, "disabled LSP integration retained semantic roles")
theme.setup()
vim.cmd.colorscheme("min-theme")
settled(id)

local second = start("min-theme-second-client")
settled(second)
assert(custom_count(second) == 6)
local first_namespace = assert(state(id)).namespace
vim.lsp.buf_detach_client(buf, id)
assert(#api.nvim_buf_get_extmarks(buf, first_namespace, 0, -1, {}) == 0, "detached client retained semantic marks")
assert(custom_count(second) == 6, "detaching one client removed the other client's roles")
vim.cmd.colorscheme("default")
assert(custom_count(second) == 0, "colorscheme switch retained theme semantic roles")
settled(second)
assert(custom_count(second) == 0 and #marks(second) > 0)
assert(#api.nvim_buf_get_extmarks(buf, roles._namespace, 0, -1, {}) == 0)
vim.lsp.get_client_by_id(id):stop(true)
vim.lsp.get_client_by_id(second):stop(true)
print(
  "semantic lifecycle: continuous typing, native cleanup, category/removal/movement, reload, toggles and multiple clients passed"
)
