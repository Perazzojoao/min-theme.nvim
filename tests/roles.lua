-- Run: nvim --headless -u NONE -i NONE -l tests/roles.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/site")
local roles = require("min-theme.integrations.roles")
local api = vim.api
local cases = {
  {
    lang = "javascript",
    source = "function f({key:p}, q=other) { let localValue=p; localValue.go(p); p.go(q); { let p=localValue; use(p); } return p; }",
    checks = {
      { "key:p", 4, "parameter" },
      { "q=other", 0, "parameter" },
      { "localValue=p", 0, "declaration" },
      { "localValue=p", 11, "parameter" },
      { "localValue.go", 0, "access" },
      { "go(p)", 3, "parameter" },
      { "p.go(q)", 0, "parameter" },
      { "p=localValue", 0, "declaration" },
      { "use(p)", 4, "standalone" },
      { "return p", 7, "parameter" },
      { "key:p", 0, false },
      { "go(p)", 0, false },
    },
  },
  {
    lang = "typescript",
    source = "function f({p}: Shape, cb: Fn) { const [v]=p; cb(); const g=(p: Other)=>p.field; return v; }",
    checks = {
      { "{p}", 1, "parameter" },
      { "cb: Fn", 0, "parameter" },
      { "cb()", 0, "parameter" },
      { "[v]", 1, "declaration" },
      { "=>p.field", 2, "parameter" },
      { "=>p.field", 4, "access" },
      { "return v", 7, "standalone" },
      { "Shape", 0, false },
      { "Other", 0, false },
    },
  },
  {
    lang = "tsx",
    source = "const f=({p}: Shape)=>{ let v=p; return <Component p={v}/>; };",
    checks = {
      { "{p}", 1, "parameter" },
      { "v=p", 0, "declaration" },
      { "v=p", 2, "parameter" },
      { "{v}", 1, "standalone" },
      { "Component", 0, false },
      { "p={v}", 0, false },
    },
  },
  {
    lang = "c_sharp",
    source = "class A { void F(int p) { var v=p; v.Go(p); p.Go(v); Func<int,int> fn=(p)=>p+1; } }",
    checks = {
      { "int p", 4, "parameter" },
      { "v=p", 0, "declaration" },
      { "v=p", 2, "parameter" },
      { "v.Go(p)", 0, "access" },
      { "v.Go(p)", 5, "parameter" },
      { "p.Go(v)", 0, "parameter" },
      { "p.Go(v)", 5, "standalone" },
      { "(p)=>", 1, "parameter" },
      { "=>p+1", 2, "parameter" },
      { "Go(p)", 0, false },
      { "A {", 0, false },
    },
  },
  {
    lang = "java",
    source = "class A { void f(int p) { int v=p; v.go(p); p.go(v); Fn fn=(p)->p+1; } }",
    checks = {
      { "int p", 4, "parameter" },
      { "v=p", 0, "declaration" },
      { "v=p", 2, "parameter" },
      { "v.go(p)", 0, "access" },
      { "v.go(p)", 5, "parameter" },
      { "p.go(v)", 0, "parameter" },
      { "p.go(v)", 5, "standalone" },
      { "(p)->", 1, "parameter" },
      { "->p+1", 2, "parameter" },
      { "go(p)", 0, false },
      { "A {", 0, false },
    },
  },
  {
    lang = "lua",
    source = "local function f(p) local v=p; v.go(p); p.go(v); local g=function(p) return p.field end; local p=p; return p end",
    checks = {
      { "f(p)", 2, "parameter" },
      { "v=p", 0, "declaration" },
      { "v=p", 2, "parameter" },
      { "v.go(p)", 0, "access" },
      { "v.go(p)", 5, "parameter" },
      { "p.go(v)", 0, "parameter" },
      { "p.go(v)", 5, "standalone" },
      { "function(p)", 9, "parameter" },
      { "p.field", 0, "parameter" },
      { "p.field", 2, "access" },
      { "local p=p", 6, "declaration" },
      { "local p=p", 8, "parameter" },
      { "return p end", 7, "standalone" },
      { "go(p)", 0, false },
    },
  },
}
cases[#cases + 1] = {
  lang = "c_sharp",
  source = "class A { void F() { var f=p=>p.Field; } }",
  checks = { { "p=>", 0, "parameter" }, { "=>p.Field", 2, "parameter" }, { "Field", 0, "access" } },
}
cases[#cases + 1] = {
  lang = "javascript",
  source = "const f=p=>p.field; function g(...args) { return args[0]; }",
  checks = {
    { "p=>", 0, "parameter" },
    { "=>p.field", 2, "parameter" },
    { "...args", 3, "parameter" },
    {
      "return args",
      7,
      "parameter",
    },
  },
}
cases[#cases + 1] = {
  lang = "c_sharp",
  source = "class A { void F() { Console.WriteLine(1); } }",
  checks = { { "Console", 0, false }, { "WriteLine", 0, false } },
}
cases[#cases + 1] = {
  lang = "lua",
  source = "local g=function() local p=1 end; return p",
  checks = { { "local p", 6, "declaration" }, { "return p", 7, false } },
}
cases[#cases + 1] = {
  lang = "c_sharp",
  source = "class A { void F(int p) { var (p2,q)=Get(); use(p2); use(q); } }",
  checks = {
    { "(p2,q)", 1, "declaration" },
    { "(p2,q)", 4, "declaration" },
    { "use(p2)", 4, "standalone" },
    { "use(q)", 4, "standalone" },
  },
}
cases[#cases + 1] = {
  lang = "c_sharp",
  source = "class A { void F() { int Local(int p) { return p; } } }",
  checks = { { "int p", 4, "parameter" }, { "return p", 7, "parameter" }, { "Local", 0, false } },
}
cases[#cases + 1] = {
  lang = "lua",
  source = "repeat local p=1 until p==1",
  checks = { { "local p", 6, "declaration" }, { "until p", 6, "standalone" } },
}
cases[#cases + 1] = {
  lang = "python",
  source = [[def f(p: Shape, cb, *args, **kwargs):
    v = p
    a, b = p
    v.go(p)
    p.go(v)
    cb()
    p = v
    for item in args:
        use(item)
    def nested():
        p = v
        return p
    g = lambda p: p.field
    return p
]],
  checks = {
    { "p: Shape", 0, "parameter" },
    { "cb,", 0, "parameter" },
    { "*args", 1, "parameter" },
    { "**kwargs", 2, "parameter" },
    { "v = p", 0, "declaration" },
    { "v = p", 4, "parameter" },
    { "a, b", 0, "declaration" },
    { "a, b", 3, "declaration" },
    { "v.go(p)", 0, "access" },
    { "v.go(p)", 5, "parameter" },
    { "p.go(v)", 0, "parameter" },
    { "p.go(v)", 5, "standalone" },
    { "cb()", 0, "parameter" },
    { "p = v", 0, "parameter" },
    { "for item", 4, "declaration" },
    { "use(item)", 4, "standalone" },
    { "        p = v", 8, "declaration" },
    { "        return p", 15, "standalone" },
    { "lambda p", 7, "parameter" },
    { "p.field", 0, "parameter" },
    { "p.field", 2, "access" },
    { "\n    return p\n", 12, "parameter" },
    { "Shape", 0, false },
    { "go(p)", 0, false },
  },
}
cases[#cases + 1] = {
  lang = "go",
  source = [[package main
func (self *Thing) F(p int, cb func(), rest ...Thing) {
    v := p
    var a, b Thing
    v.Go(p)
    self.Go(v)
    cb()
    p, extra := p, p
    { p := v; use(p) }
    g := func(p int) int { return p }
    for i, item := range rest { use(item); use(i) }
    use(v)
}
]],
  checks = {
    { "self *Thing", 0, "parameter" },
    { "p int", 0, "parameter" },
    { "cb func", 0, "parameter" },
    { "rest ...Thing", 0, "parameter" },
    { "v := p", 0, "declaration" },
    { "v := p", 5, "parameter" },
    { "a, b Thing", 0, "declaration" },
    { "a, b Thing", 3, "declaration" },
    { "v.Go(p)", 0, "access" },
    { "v.Go(p)", 5, "parameter" },
    { "self.Go(v)", 0, "parameter" },
    { "self.Go(v)", 8, "standalone" },
    { "cb()", 0, "parameter" },
    { "p, extra", 0, "parameter" },
    { "p, extra", 3, "declaration" },
    { "{ p := v", 2, "declaration" },
    { "use(p)", 4, "standalone" },
    { "func(p int)", 5, "parameter" },
    { "return p", 7, "parameter" },
    { "i, item", 0, "declaration" },
    { "i, item", 3, "declaration" },
    { "use(item)", 4, "standalone" },
    { "use(v)", 4, "standalone" },
    { "Thing", 0, false },
    { "F(p int", 0, false },
    { "Go(p)", 0, false },
  },
}
cases[#cases + 1] = {
  lang = "python",
  source = "class Thing:\n    def f(self, p: Shape, cb=None):\n        self.field = p\n        p.go(cb)\n        return self.field\n",
  checks = {
    { "self, p", 0, "parameter" },
    { "p: Shape", 0, "parameter" },
    { "cb=None", 0, "parameter" },
    { "self.field = p", 0, "parameter" },
    { "= p", 2, "parameter" },
    { "p.go(cb)", 0, "parameter" },
    { "p.go(cb)", 5, "parameter" },
    { "Thing:", 0, false },
    { "Shape", 0, false },
    { "go(cb)", 0, false },
  },
}
cases[#cases + 1] = {
  lang = "go",
  source = "package main\nfunc f(p int) (result int) { result = p; return result }",
  checks = {
    { "result int", 0, "declaration" },
    { "result = p", 0, "standalone" },
    { "= p", 2, "parameter" },
    { "return result", 7, "standalone" },
  },
}
cases[#cases + 1] = {
  lang = "python",
  source = "def f(p):\n    return [p.field for p in p.items]\n",
  checks = {
    { "f(p)", 2, "parameter" },
    { "p.field", 0, "access" },
    { "for p", 4, "declaration" },
    {
      "p.items",
      0,
      "parameter",
    },
  },
}
cases[#cases + 1] = {
  lang = "python",
  source = "def f(p):\n    def g():\n        nonlocal p\n        p = value\n        return p\n    return p\n",
  checks = {
    { "f(p)", 2, "parameter" },
    { "p = value", 0, "parameter" },
    { "        return p", 15, "parameter" },
    { "\n    return p", 12, "parameter" },
  },
}
cases[#cases + 1] = {
  lang = "python",
  source = "def f(A):\n    before = A\n    class A:\n        pass\n    return A\n",
  checks = { { "f(A)", 2, "parameter" }, { "= A", 2, "parameter" }, { "class A", 6, false }, { "return A", 7, false } },
}
cases[#cases + 1] = {
  lang = "go",
  source = "package p\nfunc f(p int) { { type p int; _ = p(1) }; _ = p }",
  checks = {
    { "f(p int", 2, "parameter" },
    { "type p int", 5, false },
    { "p(1)", 0, false },
    {
      "}; _ = p",
      7,
      "parameter",
    },
  },
}
cases[#cases + 1] = {
  lang = "go",
  source = "package p\nfunc f(p int) { { const p=1; _ = p }; _ = p }",
  checks = {
    { "f(p int", 2, "parameter" },
    { "const p", 6, false },
    { "_ = p }", 4, false },
    {
      "}; _ = p",
      7,
      "parameter",
    },
  },
}
local large_lines = { "class A { void F(int p) {" }
for i = 1, 500 do
  large_lines[#large_lines + 1] = ("var v%d = p; v%d.Go(p); use(v%d);"):format(i, i, i)
end
large_lines[#large_lines + 1] = "} }"
local large_source = table.concat(large_lines, "\n")
local large_parser = vim.treesitter.get_string_parser(large_source, "c_sharp")
local large_root = large_parser:parse()[1]:root()
local node_index = getmetatable(large_root).__index
local original_field, block_field_queries = node_index.field, 0
node_index.field = function(node, name)
  local kind = node:type()
  if kind == "block" or kind == "statement_block" then
    block_field_queries = block_field_queries + 1
  end
  return original_field(node, name)
end
local analyze_ok, large_roles = pcall(roles._analyze, large_root, large_source, "c_sharp")
node_index.field = original_field
assert(analyze_ok, "large block analysis failed: " .. tostring(large_roles))
assert(block_field_queries == 0, "eligibility queried fields on a block for each identifier")
assert(#large_roles > 500, "large block analysis skipped its identifiers")
local count = 0
for _, case in ipairs(cases) do
  local ok, parser = pcall(vim.treesitter.get_string_parser, case.source, case.lang)
  assert(ok, "required test parser unavailable: " .. case.lang)
  local root = parser:parse()[1]:root()
  assert(not root:has_error(), case.lang .. " sample has parse errors")
  local result = roles._analyze(root, case.source, case.lang)
  local by_col = {}
  local line_offsets = { [0] = 0 }
  for newline in case.source:gmatch("()\n") do
    line_offsets[#line_offsets + 1] = newline
  end
  for _, r in ipairs(result) do
    by_col[line_offsets[r[1]] + r[2]] = r.role
  end
  for _, check in ipairs(case.checks) do
    local start = assert(case.source:find(check[1], 1, true)) - 1 + check[2]
    assert(
      (by_col[start] or false) == check[3],
      case.lang .. ": " .. check[1] .. " got " .. tostring(by_col[start]) .. " expected " .. tostring(check[3])
    )
    count = count + 1
  end
end
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "function f(p) { let v=p; p.go(v); return v; }" })
vim.bo[buf].filetype = "javascript"
roles.enable({ variable_roles = true, integrations = { treesitter = true, lsp = true } })
local marks = vim.api.nvim_buf_get_extmarks(buf, roles._namespace, 0, -1, { details = true })
assert(#marks > 0, "live buffer not classified on enable")
for _, m in ipairs(marks) do
  assert(m[4].priority == 101)
end
local clear_namespace = vim.api.nvim_buf_clear_namespace
local get_changedtick = api.nvim_buf_get_changedtick
local rebuilds = 0
local refresh_checks = 0
api.nvim_buf_clear_namespace = function(buffer, namespace, ...)
  if buffer == buf and namespace == roles._namespace then
    rebuilds = rebuilds + 1
  end
  return clear_namespace(buffer, namespace, ...)
end
api.nvim_buf_get_changedtick = function(buffer, ...)
  if buffer == buf then
    refresh_checks = refresh_checks + 1
  end
  return get_changedtick(buffer, ...)
end
local checks_before_bufenter = refresh_checks
for _ = 1, 4 do
  api.nvim_exec_autocmds("BufEnter", { buffer = buf })
end
assert(
  vim.wait(500, function()
    return refresh_checks > checks_before_bufenter
  end, 5),
  "unchanged BufEnter refresh did not settle"
)
api.nvim_buf_clear_namespace = clear_namespace
api.nvim_buf_get_changedtick = get_changedtick
assert(rebuilds == 0, "unchanged BufEnter rebuilt syntax marks")
local end_col = #vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
vim.api.nvim_buf_set_text(buf, 0, end_col, 0, end_col, { " // typing" })
assert(
  #vim.api.nvim_buf_get_extmarks(buf, roles._namespace, 0, -1, {}) == #marks,
  "syntax roles disappeared while an edit was waiting for classification"
)
local lsp_ns = vim.api.nvim_create_namespace("min-theme.test-semantic-tokens")
local highlight_token, force_refresh = vim.lsp.semantic_tokens.highlight_token, vim.lsp.semantic_tokens.force_refresh
-- Unit tests supply semantic snapshots; semantic_lifecycle.lua exercises the native engine.
vim.lsp.semantic_tokens.highlight_token = function(token, buffer, client, hl_group, opts)
  assert(client == 999)
  vim.api.nvim_buf_set_extmark(buffer, lsp_ns, token.line, token.start_col, {
    end_row = token.line,
    end_col = token.end_col,
    hl_group = hl_group,
    priority = opts.priority,
  })
end
vim.lsp.semantic_tokens.force_refresh = function(buffer)
  vim.api.nvim_buf_clear_namespace(buffer, lsp_ns, 0, -1)
end
local function send(type, col, mods)
  vim.api.nvim_buf_clear_namespace(buf, lsp_ns, 0, -1)
  vim.api.nvim_exec_autocmds("LspTokenUpdate", {
    buffer = buf,
    data = {
      client_id = 999,
      token = {
        type = type,
        line = 0,
        start_col = col,
        end_col = col + 1,
        modifiers = mods or {},
      },
    },
  })
  return vim.api.nvim_buf_get_extmarks(buf, lsp_ns, 0, -1, { details = true })
end
local col = assert(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]:find("p.go", 1, true)) - 1
local got = send("parameter", col)
assert(#got == 1 and got[1][4].priority == 130 and got[1][4].hl_group == "@variable.parameter")
got = send("variable", col)
assert(
  #got == 1 and got[1][4].priority == 128 and got[1][4].hl_group == "@variable.access",
  "semantic variable must replace AST parameter receiver"
)
got = send("method", col)
assert(#got == 0, "stale overlay survived semantic category change")
got = send("variable", col, { declaration = true })
assert(#got == 1 and got[1][4].priority == 129 and got[1][4].hl_group == "@variable.declaration")
-- LSP identity is sufficient even for globals absent from lexical bindings.
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "external.value; use(external);" })
col = 0
got = send("variable", col, { readonly = true })
assert(#got > 0 and got[1][4].hl_group == "@variable.access" and got[1][4].priority == 128)
col = 20
got = send("property", col)
local standalone = false
for _, mark in ipairs(got) do
  if mark[3] == col then
    standalone = mark[4].hl_group == "@variable.standalone"
  end
end
assert(standalone, "LSP property used independently must be white")
roles.disable()
assert(#vim.api.nvim_buf_get_extmarks(buf, lsp_ns, 0, -1, {}) == 0)
assert(#vim.api.nvim_buf_get_extmarks(buf, roles._namespace, 0, -1, {}) == 0)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "function f(p) { let v=p; p.go(v); return v; }" })
col = 24
roles.enable({ variable_roles = false, integrations = { treesitter = true, lsp = true } })
for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, roles._namespace, 0, -1, { details = true })) do
  assert(m[4].hl_group == "@variable.parameter")
end
assert(#send("variable", col) == 0)
assert(#send("parameter", col) == 1)
local ts_disabled_parser = vim.treesitter.get_parser
vim.treesitter.get_parser = function()
  error("must not parse when treesitter integration is disabled")
end
roles.enable({ variable_roles = true, integrations = { treesitter = false, lsp = true } })
assert(#send("parameter", col) == 1)
assert(#send("variable", col, { declaration = true }) == 1)
local fallback = send("variable", col)
assert(#fallback == 1 and fallback[1][4].hl_group == "@variable.access")
vim.treesitter.get_parser = ts_disabled_parser
roles.enable({ variable_roles = true, integrations = { treesitter = false, lsp = false } })
assert(#vim.api.nvim_buf_get_extmarks(buf, roles._namespace, 0, -1, {}) == 0)
assert(#send("parameter", col) == 0)
-- Unsupported grammar and missing parser both leave static highlighting in control.
vim.bo[buf].filetype = "unsupported_min_theme_test"
roles.enable({ variable_roles = true, integrations = { treesitter = true, lsp = true } })
assert(#vim.api.nvim_buf_get_extmarks(buf, roles._namespace, 0, -1, {}) == 0)
local get_parser = vim.treesitter.get_parser
vim.treesitter.get_parser = function()
  error("test missing parser")
end
vim.bo[buf].filetype = "javascript"
roles.enable({ variable_roles = true, integrations = { treesitter = true, lsp = true } })
assert(#vim.api.nvim_buf_get_extmarks(buf, roles._namespace, 0, -1, {}) == 0, "missing parser must fall back")
vim.treesitter.get_parser = get_parser
roles.enable({ variable_roles = true, integrations = { treesitter = true, lsp = true } })
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "function changed(param) { return param; }" })
assert(
  vim.wait(250, function()
    local result = vim.api.nvim_buf_get_extmarks(buf, roles._namespace, 0, -1, { details = true })
    return #result == 2 and result[1][4].hl_group == "@variable.parameter"
  end),
  "live edits did not rebuild roles"
)
local get_at_pos = vim.lsp.semantic_tokens.get_at_pos
vim.lsp.semantic_tokens.get_at_pos = function(_, row, column)
  if row == 0 and column == 17 then
    return { { client_id = 999, type = "parameter", line = 0, start_col = 17, end_col = 22, modifiers = {} } }
  end
  return {}
end
roles.enable({ variable_roles = true, integrations = { treesitter = true, lsp = true } })
assert(
  #vim.api.nvim_buf_get_extmarks(buf, lsp_ns, 0, -1, {}) == 1,
  "existing semantic tokens were not hydrated on reload"
)
vim.lsp.semantic_tokens.get_at_pos = get_at_pos
vim.api.nvim_exec_autocmds("ColorSchemePre", {})
assert(#vim.api.nvim_buf_get_extmarks(buf, roles._namespace, 0, -1, {}) == 0, "theme switch did not clear overlays")
assert(#vim.api.nvim_buf_get_extmarks(buf, lsp_ns, 0, -1, {}) == 0, "theme switch did not refresh semantic overrides")
local stale_buf = api.nvim_create_buf(false, true)
api.nvim_buf_set_lines(stale_buf, 0, -1, false, { "function stale(p) { return p; }" })
vim.bo[stale_buf].filetype = "javascript"
local scheduled_roles, original_schedule = {}, vim.schedule
vim.schedule = function(callback)
  local source = debug.getinfo(callback, "S").source
  if source:find("roles.lua", 1, true) then
    scheduled_roles[#scheduled_roles + 1] = callback
  else
    original_schedule(callback)
  end
end
roles.enable({ variable_roles = true, integrations = { treesitter = true, lsp = true } })
api.nvim_buf_set_lines(stale_buf, 0, 0, false, { "// edit" })
assert(roles._timers[stale_buf], "edit did not allocate a per-buffer debounce timer")
assert(
  vim.wait(500, function()
    return #scheduled_roles > 0
  end, 5),
  "debounce timer did not schedule its refresh"
)
api.nvim_buf_set_lines(stale_buf, 0, 0, false, { "// newer edit" })
clear_namespace = api.nvim_buf_clear_namespace
local superseded_rebuilds = 0
api.nvim_buf_clear_namespace = function(buffer, namespace, ...)
  if buffer == stale_buf and namespace == roles._namespace then
    superseded_rebuilds = superseded_rebuilds + 1
  end
  return clear_namespace(buffer, namespace, ...)
end
scheduled_roles[1]()
api.nvim_buf_clear_namespace = clear_namespace
assert(superseded_rebuilds == 0, "superseded scheduled refresh ignored its generation")
roles.disable()
assert(not roles._timers[stale_buf], "disable retained a debounce timer")
roles.enable({ variable_roles = true, integrations = { treesitter = true, lsp = true } })
clear_namespace = api.nvim_buf_clear_namespace
local stale_rebuilds = 0
api.nvim_buf_clear_namespace = function(buffer, namespace, ...)
  if buffer == stale_buf and namespace == roles._namespace then
    stale_rebuilds = stale_rebuilds + 1
  end
  return clear_namespace(buffer, namespace, ...)
end
for _, callback in ipairs(scheduled_roles) do
  callback()
end
api.nvim_buf_clear_namespace = clear_namespace
vim.schedule = original_schedule
assert(stale_rebuilds == 0, "stale timer callback refreshed after disable and re-enable")
api.nvim_buf_set_lines(stale_buf, 0, 0, false, { "// colorscheme change" })
assert(roles._timers[stale_buf], "edit did not allocate a timer before colorscheme cleanup")
api.nvim_exec_autocmds("ColorSchemePre", {})
assert(not roles._timers[stale_buf], "colorscheme cleanup retained a debounce timer")
roles.enable({ variable_roles = true, integrations = { treesitter = true, lsp = true } })
local detached_buf = api.nvim_create_buf(false, true)
api.nvim_buf_set_lines(detached_buf, 0, -1, false, { "function detached(p) { return p; }" })
vim.bo[detached_buf].filetype = "javascript"
api.nvim_exec_autocmds("BufEnter", { buffer = detached_buf })
assert(roles._timers[detached_buf], "BufEnter did not allocate a debounce timer")
api.nvim_buf_delete(detached_buf, { unload = true })
assert(not roles._timers[detached_buf], "detach retained a debounce timer")
assert(api.nvim_buf_is_valid(detached_buf) and not api.nvim_buf_is_loaded(detached_buf), "unload test wiped the buffer")
local wiped_buf = api.nvim_create_buf(false, true)
api.nvim_buf_set_lines(wiped_buf, 0, -1, false, { "function wiped(p) { return p; }" })
vim.bo[wiped_buf].filetype = "javascript"
api.nvim_exec_autocmds("BufEnter", { buffer = wiped_buf })
assert(roles._timers[wiped_buf], "BufEnter did not allocate a timer before wipeout")
api.nvim_buf_delete(wiped_buf, { force = true })
assert(not roles._timers[wiped_buf], "wipeout retained a debounce timer")
roles.disable()
vim.lsp.semantic_tokens.highlight_token, vim.lsp.semantic_tokens.force_refresh = highlight_token, force_refresh
print(
  "roles: "
    .. count
    .. " AST assertions across eight grammars; live overlays, semantic authority, cleanup and integration toggles passed"
)
