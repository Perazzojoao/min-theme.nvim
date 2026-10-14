-- Syntax overlays belong to the theme; semantic overlays follow Neovim's token lifecycle.
local M = {}
local api = vim.api
local syntax_ns = api.nvim_create_namespace("min-theme.variable-roles")
local enabled, options, group = false, {}, nil
local caches, attached, generations, semantic_buffers = {}, {}, {}, {}
local rendered, timers = {}, {}
local generation_sequence, enable_epoch, config_generation = 0, 0, 0
local supported = {
  c_sharp = true,
  java = true,
  javascript = true,
  typescript = true,
  tsx = true,
  lua = true,
  python = true,
  go = true,
}
local functions = {
  function_declaration = true,
  function_definition = true,
  function_expression = true,
  generator_function = true,
  generator_function_declaration = true,
  arrow_function = true,
  lambda_expression = true,
  method_declaration = true,
  constructor_declaration = true,
  method_definition = true,
  local_function = true,
  local_function_statement = true,
  lambda = true,
  func_literal = true,
}
local scopes = {
  block = true,
  statement_block = true,
  class_body = true,
  declaration_list = true,
  for_statement = true,
  foreach_statement = true,
  enhanced_for_statement = true,
  catch_clause = true,
  for_numeric_statement = true,
  for_generic_statement = true,
  do_statement = true,
  while_statement = true,
  repeat_statement = true,
  class_definition = true,
  list_comprehension = true,
  set_comprehension = true,
  dictionary_comprehension = true,
  generator_expression = true,
  if_statement = true,
  expression_switch_statement = true,
  type_switch_statement = true,
  expression_case = true,
  type_case = true,
  default_case = true,
}
local identifiers = {
  identifier = true,
  implicit_parameter = true,
  shorthand_property_identifier = true,
  shorthand_property_identifier_pattern = true,
  property_identifier = true,
  private_property_identifier = true,
  field_identifier = true,
}
local access_fields = {
  member_access_expression = { "expression", "name" },
  conditional_access_expression = { "condition" },
  member_binding_expression = { "name" },
  member_expression = { "object", "property" },
  field_access = { "object", "field" },
  method_invocation = { "object" },
  dot_index_expression = { "table", "field" },
  method_index_expression = { "table", "method" },
  element_access_expression = { "expression" },
  array_access = { "array" },
  subscript_expression = { "object" },
  bracket_index_expression = { "table" },
  attribute = { "object", "attribute" },
  subscript = { "value" },
  selector_expression = { "operand", "field" },
  index_expression = { "operand" },
  slice_expression = { "operand" },
}
local function field(node, name)
  return node:field(name)[1]
end
local function same(a, b)
  return a and b and a:id() == b:id()
end
local function access(node)
  while node do
    local parent = node:parent()
    if not parent then
      return false
    end
    local kind = parent:type()
    if access_fields[kind] then
      for _, name in ipairs(access_fields[kind]) do
        if same(field(parent, name), node) then
          return true
        end
      end
      return false -- arguments and index expressions are standalone expressions.
    end
    local transparent = kind == "parenthesized_expression" or kind == "non_null_expression"
    if kind == "cast_expression" then
      transparent = same(field(parent, "value"), node)
    end
    if kind == "postfix_unary_expression" then
      local last = parent:child(parent:child_count() - 1)
      transparent = last and last:type() == "!"
    end
    if not transparent then
      return false
    end
    node = parent
  end
  return false
end
-- Extract binding names, excluding destructuring keys, computed names and defaults.
local function pattern(node, add)
  if not node then
    return
  end
  local kind = node:type()
  if kind == "identifier" or kind == "implicit_parameter" or kind == "shorthand_property_identifier_pattern" then
    add(node)
    return
  end
  if kind == "pair_pattern" then
    pattern(field(node, "value"), add)
    return
  end
  if kind == "assignment_pattern" or kind == "object_assignment_pattern" then
    pattern(field(node, "left"), add)
    return
  end
  if kind == "default_parameter" or kind == "typed_default_parameter" then
    pattern(field(node, "name"), add)
    return
  end
  if kind == "typed_parameter" then
    for child in node:iter_children() do
      if child:named() and not same(field(node, "type"), child) then
        pattern(child, add)
      end
    end
    return
  end
  if kind == "parameter_declaration" or kind == "variadic_parameter_declaration" then
    for _, name in ipairs(node:field("name")) do
      pattern(name, add)
    end
    return
  end
  if kind == "required_parameter" or kind == "optional_parameter" then
    pattern(field(node, "pattern"), add)
    return
  end
  if
    kind == "parameter"
    or kind == "formal_parameter"
    or kind == "spread_parameter"
    or kind == "catch_formal_parameter"
  then
    local name = field(node, "name")
    if name then
      pattern(name, add)
    else
      for child in node:iter_children() do
        if child:type() == "variable_declarator" then
          pattern(field(child, "name"), add)
        end
      end
    end
    return
  end
  if
    kind == "object_pattern"
    or kind == "array_pattern"
    or kind == "rest_pattern"
    or kind == "tuple_pattern"
    or kind == "formal_parameters"
    or kind == "parameter_list"
    or kind == "inferred_parameters"
    or kind == "parameters"
    or kind == "variable_list"
    or kind == "lambda_parameters"
    or kind == "pattern_list"
    or kind == "list_pattern"
    or kind == "list_splat_pattern"
    or kind == "dictionary_splat_pattern"
    or kind == "expression_list"
  then
    for child in node:iter_children() do
      if child:named() then
        pattern(child, add)
      end
    end
  end
end
local function eligible(node)
  local child = node
  local parent = node:parent()
  while parent do
    local kind = parent:type()
    if kind == "statement_block" or kind == "block" then
      -- These blocks have no type or returns fields; avoid querying them for each identifier.
      break
    end
    -- A known binding can share a spelling with a type, method or object key.
    if kind:find("type") and kind ~= "type_assertion" and kind ~= "typeof_expression" then
      return false
    end
    if
      (functions[kind] or kind == "class_declaration" or kind == "interface_declaration" or kind == "class_definition")
      and same(field(parent, "name"), child)
    then
      return false
    end
    if kind == "method_invocation" and same(field(parent, "name"), node) then
      return false
    end
    if kind == "generic_name" or kind == "global_statement" or kind == "nonlocal_statement" then
      return false
    end
    if kind == "jsx_attribute" and child:type() == "property_identifier" then
      return false
    end
    if
      access_fields[kind]
      and (
        same(field(parent, "property"), node)
        or same(field(parent, "field"), node)
        or same(field(parent, "name"), node)
        or same(field(parent, "method"), node)
        or same(field(parent, "attribute"), node)
      )
    then
      local grand = parent:parent()
      if grand and (same(field(grand, "function"), parent) or same(field(grand, "name"), parent)) then
        return false
      end
    end
    if
      (kind == "pair" or kind == "pair_pattern" or kind == "field")
      and same(field(parent, "key") or field(parent, "name"), child)
    then
      return false
    end
    if
      (
        kind == "jsx_opening_element"
        or kind == "jsx_closing_element"
        or kind == "jsx_self_closing_element"
        or kind == "jsx_attribute"
      ) and same(field(parent, "name"), child)
    then
      return false
    end
    if same(field(parent, "type"), child) or same(field(parent, "returns"), child) then
      return false
    end
    if functions[kind] then
      break
    end
    child, parent = parent, parent:parent()
  end
  return true
end
local function analyze(root, buf, lang)
  local nodes, declarations, node_scopes = {}, {}, {}
  local function walk(node, scope)
    local kind = node:type()
    local parent = node:parent()
    local repeat_body = lang == "lua" and kind == "block" and parent and parent:type() == "repeat_statement"
    local transparent = repeat_body
      or (lang == "python" and not functions[kind] and kind ~= "class_definition" and not kind:find("comprehension") and kind ~= "generator_expression")
      or (lang == "go" and kind == "block" and parent and functions[parent:type()])
    if not scope or functions[kind] or (scopes[kind] and not transparent) then
      scope = { parent = scope, bindings = {}, node = node, externals = {} }
    end
    node_scopes[node:id()] = scope
    local function bind(n, role, target)
      if not n then
        return
      end
      local name = vim.treesitter.get_node_text(n, buf)
      if lang == "go" and name == "_" then
        return
      end
      target = target or scope
      target.bindings[name] = target.bindings[name] or {}
      local visibility = 0
      if
        ((lang == "lua" or lang == "go") and role == "variable" and not functions[node:type()])
        or (lang == "python" and node:type() == "class_definition")
        or (lang == "go" and (node:type() == "type_spec" or node:type() == "type_alias" or node:type() == "const_spec"))
      then
        local _, _, _, _, _, last = node:range(true)
        visibility = last
      end
      table.insert(target.bindings[name], { role = role, node = n, visibility = visibility, owner = node })
      declarations[n:id()] = role
    end
    if lang == "python" and kind == "class_definition" then
      bind(field(node, "name"), "other", scope.parent or scope)
    end
    if lang == "go" and (kind == "type_spec" or kind == "type_alias" or kind == "const_spec") then
      for _, name in ipairs(node:field("name")) do
        bind(name, "other")
      end
    end
    if functions[kind] then
      local name = field(node, "name")
      if name then
        bind(name, "other", scope.parent or scope)
      end
      pattern(field(node, "parameters") or field(node, "parameter"), function(n)
        bind(n, "parameter")
      end)
      if lang == "go" then
        pattern(field(node, "receiver"), function(n)
          bind(n, "parameter")
        end)
        pattern(field(node, "result"), function(n)
          bind(n, "variable")
        end)
      end
    end
    local function python_binding(n)
      local name = vim.treesitter.get_node_text(n, buf)
      if scope.externals[name] then
        return
      end
      local existing = scope.bindings[name]
      bind(n, existing and existing[#existing].role == "parameter" and "parameter" or "variable")
    end
    if lang == "python" and (kind == "global_statement" or kind == "nonlocal_statement") then
      for child in node:iter_children() do
        if child:type() == "identifier" then
          scope.externals[vim.treesitter.get_node_text(child, buf)] = kind
        end
      end
    elseif lang == "python" and (kind == "assignment" or kind == "for_statement" or kind == "for_in_clause") then
      pattern(field(node, "left"), python_binding)
    elseif lang == "go" and kind == "short_var_declaration" then
      pattern(field(node, "left"), function(n)
        local name = vim.treesitter.get_node_text(n, buf)
        local old = scope.bindings[name]
        if name ~= "_" then
          if old then
            declarations[n:id()] = old[#old].role
          else
            bind(n, "variable")
          end
        end
      end)
    elseif lang == "go" and kind == "var_spec" then
      for _, name in ipairs(node:field("name")) do
        pattern(name, function(n)
          bind(n, "variable")
        end)
      end
    elseif lang == "go" and kind == "range_clause" then
      local text = vim.treesitter.get_node_text(node, buf)
      if text:find(":=", 1, true) then
        pattern(field(node, "left"), function(n)
          bind(n, "variable")
        end)
      end
    elseif kind == "variable_declarator" then
      local target = scope
      -- JavaScript var bindings belong to their enclosing function, unlike let/const.
      if lang == "javascript" or lang == "typescript" or lang == "tsx" then
        local parent = node:parent()
        if parent and parent:type() == "variable_declaration" then
          while target.parent and not functions[target.node:type()] do
            target = target.parent
          end
        end
      end
      local name = field(node, "name")
      if name then
        pattern(name, function(n)
          bind(n, "variable", target)
        end)
      else
        for child in node:iter_children() do
          if child:type() == "tuple_pattern" then
            pattern(child, function(n)
              bind(n, "variable", target)
            end)
          end
        end
      end
    elseif kind == "declaration_expression" or kind == "declaration_pattern" or kind == "property_declaration" then
      pattern(field(node, "name"), function(n)
        bind(n, "variable")
      end)
    elseif kind == "foreach_statement" then
      pattern(field(node, "left"), function(n)
        bind(n, "variable")
      end)
    elseif kind == "enhanced_for_statement" then
      pattern(field(node, "name"), function(n)
        bind(n, "variable")
      end)
    elseif kind == "catch_formal_parameter" then
      pattern(node, function(n)
        bind(n, "variable")
      end)
    elseif kind == "catch_clause" then
      pattern(field(node, "parameter"), function(n)
        bind(n, "variable")
      end)
    elseif lang == "lua" and kind == "variable_declaration" then
      for child in node:iter_children() do
        if child:type() == "variable_list" then
          pattern(child, function(n)
            bind(n, "variable")
          end)
        elseif child:type() == "assignment_statement" then
          for list in child:iter_children() do
            if list:type() == "variable_list" then
              pattern(list, function(n)
                bind(n, "variable")
              end)
            end
          end
        end
      end
    elseif lang == "lua" and kind == "for_numeric_clause" then
      pattern(field(node, "name"), function(n)
        bind(n, "variable")
      end)
    elseif lang == "lua" and kind == "for_generic_clause" then
      for c in node:iter_children() do
        if c:type() == "variable_list" then
          pattern(c, function(n)
            bind(n, "variable")
          end)
        end
      end
    end
    if identifiers[kind] then
      nodes[#nodes + 1] = node
    end
    for child in node:iter_children() do
      if child:named() then
        walk(child, scope)
      end
    end
  end
  walk(root)
  local result, index = {}, {}
  for _, node in ipairs(nodes) do
    local row, col = node:range()
    index[row .. ":" .. col] = node
    local role = declarations[node:id()]
    local parent = node:parent()
    local property = parent
      and (
        same(field(parent, "attribute"), node)
        or same(field(parent, "method"), node)
        or same(field(parent, "property"), node)
        or same(field(parent, "field"), node)
        or (access_fields[parent:type()] and same(field(parent, "name"), node))
      )
    if
      not role
      and not property
      and node:type() ~= "property_identifier"
      and node:type() ~= "private_property_identifier"
      and node:type() ~= "field_identifier"
      and eligible(node)
    then
      local name = vim.treesitter.get_node_text(node, buf)
      local scope = node_scopes[node:id()]
      while scope do
        if lang == "python" and scope.externals[name] == "global_statement" then
          while scope.parent do
            scope = scope.parent
          end
        end
        local bindings = scope.bindings[name]
        if bindings then
          local _, _, start = node:range(true)
          local clause_start
          if lang == "python" then
            local ancestor = node:parent()
            while ancestor and ancestor ~= scope.node do
              if ancestor:type() == "for_in_clause" then
                local right = field(ancestor, "right")
                if right then
                  local _, _, first, _, _, last = right:range(true)
                  if start >= first and start < last then
                    local _, _, position = ancestor:range(true)
                    clause_start = position
                  end
                end
                break
              end
              ancestor = ancestor:parent()
            end
          end
          for i = #bindings, 1, -1 do
            local binding = bindings[i]
            local iterable_binding = false
            if clause_start and binding.owner:type() == "for_in_clause" then
              local _, _, position = binding.owner:range(true)
              iterable_binding = position >= clause_start
            end
            if start >= binding.visibility and not iterable_binding then
              role = binding.role
              break
            end
          end
          if role then
            break
          end
        end
        scope = scope.parent
      end
    end
    local member = access(node)
    local callable = parent
      and (
        same(field(parent, "function"), node)
        or ((parent:type() == "function_call" or parent:type() == "call") and same(field(parent, "name"), node))
      )
    if callable and role ~= "parameter" then
      role = nil
    end
    if not role and member and property and eligible(node) then
      role = "access"
    end
    if role and role ~= "other" and (options.variable_roles ~= false or role == "parameter") then
      local sr, sc, er, ec = node:range()
      result[#result + 1] = {
        sr,
        sc,
        er,
        ec,
        role = role == "parameter" and "parameter"
          or declarations[node:id()] and "declaration"
          or member and "access"
          or "standalone",
        access = member,
      }
    end
  end
  return result, index
end
local function language(buf)
  local ft = vim.bo[buf].filetype
  local lang = vim.treesitter.language.get_lang(ft) or ft
  return supported[lang] and lang or nil
end
local function cache(buf)
  local tick = api.nvim_buf_get_changedtick(buf)
  local lang = language(buf)
  local old = caches[buf]
  if old and old.tick == tick and old.lang == lang then
    return old
  end
  local result = { tick = tick, lang = lang, roles = {}, nodes = {} }
  if lang then
    local ok, roles, nodes = pcall(function()
      local parser = vim.treesitter.get_parser(buf, lang)
      local trees = parser:parse()
      if trees and trees[1] then
        return analyze(trees[1]:root(), buf, lang)
      end
      return {}, {}
    end)
    if ok then
      result.roles = roles
      result.nodes = nodes or {}
    end
  end
  caches[buf] = result
  return result
end
local role_groups = {
  parameter = "@variable.parameter",
  declaration = "@variable.declaration",
  access = "@variable.access",
  standalone = "@variable.standalone",
}
local function refresh(buf)
  if not enabled or not api.nvim_buf_is_valid(buf) or not api.nvim_buf_is_loaded(buf) then
    return
  end
  local tick = api.nvim_buf_get_changedtick(buf)
  local lang = language(buf)
  local previous = rendered[buf]
  if
    previous
    and previous.tick == tick
    and previous.lang == lang
    and previous.config_generation == config_generation
  then
    return
  end
  local roles = options.integrations.treesitter and cache(buf).roles or {}
  api.nvim_buf_clear_namespace(buf, syntax_ns, 0, -1)
  if options.integrations.treesitter then
    for _, r in ipairs(roles) do
      api.nvim_buf_set_extmark(
        buf,
        syntax_ns,
        r[1],
        r[2],
        { end_row = r[3], end_col = r[4], hl_group = role_groups[r.role], priority = 101 }
      )
    end
  end
  rendered[buf] = { tick = tick, lang = lang, config_generation = config_generation }
end
local function close_timer(buf)
  local timer = timers[buf]
  if timer then
    timer:stop()
    if not timer:is_closing() then
      timer:close()
    end
    timers[buf] = nil
  end
end
local function queue(buf)
  generation_sequence = generation_sequence + 1
  local generation, epoch = generation_sequence, enable_epoch
  generations[buf] = generation
  local timer = timers[buf]
  if not timer then
    timer = vim.uv.new_timer()
    timers[buf] = timer
  end
  timer:stop()
  timer:start(30, 0, function()
    vim.schedule(function()
      if enabled and enable_epoch == epoch and generations[buf] == generation then
        pcall(refresh, buf)
      end
    end)
  end)
end
local function detach(buf)
  attached[buf], caches[buf], rendered[buf] = nil, nil, nil
  close_timer(buf)
  generation_sequence = generation_sequence + 1
  local generation, epoch = generation_sequence, enable_epoch
  generations[buf] = generation
  semantic_buffers[buf] = nil
  vim.schedule(function()
    if generations[buf] == generation and enable_epoch == epoch and api.nvim_buf_is_valid(buf) then
      pcall(api.nvim_buf_clear_namespace, buf, syntax_ns, 0, -1)
    end
  end)
end
local function attach(buf)
  if attached[buf] or not api.nvim_buf_is_loaded(buf) then
    return
  end
  attached[buf] = api.nvim_buf_attach(buf, false, {
    on_lines = function(_, b)
      caches[b], rendered[b] = nil, nil
      -- Extmarks track edits while fresh syntax and semantic classifications are pending.
      if enabled then
        queue(b)
      end
    end,
    on_detach = function(_, b)
      detach(b)
    end,
  }) or nil
end
local function token_update(event)
  if not enabled or not options.integrations.lsp then
    return
  end
  local data = event.data or {}
  local token, id = data.token, data.client_id
  if not token or not id then
    return
  end
  local buf = event.buf
  local key = token.line .. ":" .. token.start_col
  local role, priority
  if token.type == "parameter" then
    role, priority = "parameter", 130
  elseif
    options.variable_roles ~= false and (token.type == "variable" or token.type == "field" or token.type == "property")
  then
    local mods = token.modifiers or {}
    if mods.declaration or mods.definition then
      role, priority = "declaration", 129
    else
      -- The semantic category proves identity; bindings are only necessary without LSP.
      -- Exact AST positions distinguish receivers from independent argument expressions.
      local node = options.integrations.treesitter and cache(buf).nodes[key] or nil
      role = node and (access(node) and "access" or "standalone") or "access"
      priority = 128
    end
  end
  if role then
    -- Native tokens persist during debounce and remove these marks with the next token batch,
    -- including symbols that disappear or change to a non-variable semantic category.
    vim.lsp.semantic_tokens.highlight_token(token, buf, id, role_groups[role], { priority = priority })
    semantic_buffers[buf] = true
  end
end
local function hydrate(buf)
  if not enabled or not options.integrations.lsp or not options.integrations.treesitter then
    return
  end
  local tokens = vim.lsp.semantic_tokens
  if not tokens or type(tokens.get_at_pos) ~= "function" then
    return
  end
  -- Re-read known positions through the public API when native tokens are already available.
  for _, node in pairs(cache(buf).nodes) do
    local row, col = node:range()
    local ok, found = pcall(tokens.get_at_pos, buf, row, col)
    if ok then
      for _, token in ipairs(found or {}) do
        pcall(token_update, { buf = buf, data = { token = token, client_id = token.client_id } })
      end
    end
  end
end
function M.disable()
  enabled = false
  enable_epoch = enable_epoch + 1
  if group then
    pcall(api.nvim_del_augroup_by_id, group)
    group = nil
  end
  for _, buf in ipairs(api.nvim_list_bufs()) do
    pcall(api.nvim_buf_clear_namespace, buf, syntax_ns, 0, -1)
    if semantic_buffers[buf] then
      -- Refresh through Neovim so native and other plugins' token callbacks are rebuilt
      -- without this theme's overrides after disabling or switching colorschemes.
      pcall(vim.lsp.semantic_tokens.force_refresh, buf)
    end
  end
  for buf in pairs(timers) do
    close_timer(buf)
  end
  caches, generations, rendered, semantic_buffers = {}, {}, {}, {}
  -- Buffer callbacks stay attached but dormant, avoiding duplicate callbacks on re-enable.
end
function M.enable(config)
  M.disable()
  options = config or {}
  options.integrations = options.integrations or { treesitter = true, lsp = true }
  config_generation = config_generation + 1
  enabled = true
  group = api.nvim_create_augroup("min-theme-variable-roles", { clear = true })
  api.nvim_create_autocmd({ "BufEnter", "BufReadPost", "FileType" }, {
    group = group,
    callback = function(e)
      attach(e.buf)
      queue(e.buf)
    end,
  })
  api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(e)
      caches[e.buf], generations[e.buf], rendered[e.buf], attached[e.buf] = nil, nil, nil, nil
      close_timer(e.buf)
      semantic_buffers[e.buf] = nil
    end,
  })
  api.nvim_create_autocmd("LspTokenUpdate", {
    group = group,
    callback = function(e)
      pcall(token_update, e)
    end,
  })
  api.nvim_create_autocmd("ColorSchemePre", { group = group, callback = M.disable })
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(buf) then
      attach(buf)
      pcall(refresh, buf)
      pcall(hydrate, buf)
    end
  end
end
-- Exposed for integration tests and inspection; no runtime query registration.
M._namespace = syntax_ns
M._analyze = analyze
M._cache = cache
M._timers = timers
return M
