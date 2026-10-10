local M = {}

local SOURCE_PATH = "lua/min-theme/resources/min-dark-vscode-color-map.json"
local SOURCE_COMMIT = "dd796c3f294daecfb7f10ed277ffdc30517d59cf"
local SOURCE_SHA256 = "617a7949326293695e7cd1d0ad169ddb96ebf34929e8bb88bf3f79b40e2992c5"
local EXPECTED_COLOR_COUNT = 105

local cached_source

local function fail(message)
  error("min-theme adapter: " .. message, 2)
end

local function load_source()
  if cached_source then
    return cached_source
  end
  local paths = vim.api.nvim_get_runtime_file(SOURCE_PATH, false)
  if not paths or not paths[1] then
    fail(("could not find %s on runtimepath"):format(SOURCE_PATH))
  end
  local ok, contents = pcall(vim.fn.readfile, paths[1])
  if not ok then
    fail(("could not read %s: %s"):format(paths[1], contents))
  end
  local decoded, source = pcall(vim.json.decode, table.concat(contents, "\n"))
  if not decoded then
    fail(("invalid JSON in %s: %s"):format(paths[1], source))
  end
  if
    type(source) ~= "table"
    or type(source.source) ~= "table"
    or source.source.repository ~= "https://github.com/miguelsolorio/min-theme.git"
    or source.source.commit ~= SOURCE_COMMIT
    or source.source.theme_source_sha256 ~= SOURCE_SHA256
    or source.source.theme_file ~= "themes/min-dark.json"
    or type(source.theme_definition) ~= "table"
    or type(source.theme_definition.colors) ~= "table"
    or type(source.theme_definition.tokenColors) ~= "table"
    or type(source.color_key_values) ~= "table"
    or #source.color_key_values ~= EXPECTED_COLOR_COUNT
    or type(source.summary) ~= "table"
    or source.summary.total_color_key_values ~= EXPECTED_COLOR_COUNT
  then
    fail("source identity or shape does not match the pinned Min Dark palette")
  end

  for _, record in ipairs(source.color_key_values) do
    if type(record) ~= "table" or type(record.json_pointer) ~= "string" or type(record.value) ~= "string" then
      fail("source contains a malformed color_key_values record")
    end
    local color_key = record.json_pointer:match("^/colors/(.+)$")
    local token_index = record.json_pointer:match("^/tokenColors/(%d+)/settings/foreground$")
    local current
    if color_key then
      current = source.theme_definition.colors[color_key]
    elseif token_index then
      local rule = source.theme_definition.tokenColors[tonumber(token_index) + 1]
      current = rule and rule.settings and rule.settings.foreground
    else
      fail("source contains an unsupported color pointer: " .. record.json_pointer)
    end
    if current ~= record.value then
      fail("source value does not match its pointer: " .. record.json_pointer)
    end
  end

  cached_source = source
  return cached_source
end

local function normalize_color(value)
  if type(value) ~= "string" then
    return nil, nil
  end
  local hex = value:match("^#(%x+)$")
  if not hex then
    return nil, nil
  end
  if #hex == 3 or #hex == 4 then
    local expanded = {}
    for index = 1, #hex do
      expanded[index] = hex:sub(index, index):rep(2)
    end
    hex = table.concat(expanded)
  end
  if #hex == 6 then
    return "#" .. hex:lower(), 255
  end
  if #hex == 8 then
    return "#" .. hex:sub(1, 6):lower(), tonumber(hex:sub(7, 8), 16)
  end
  return nil, nil
end

local function rgb(color)
  local normalized = normalize_color(color)
  if not normalized then
    return nil
  end
  return {
    tonumber(normalized:sub(2, 3), 16),
    tonumber(normalized:sub(4, 5), 16),
    tonumber(normalized:sub(6, 7), 16),
  }
end

local function composite(foreground, background, alpha)
  local front = rgb(foreground)
  local back = rgb(background)
  if not front or not back then
    fail("cannot composite an alpha color without valid foreground and background colors")
  end
  local ratio = alpha / 255
  local channels = {}
  for index = 1, 3 do
    channels[index] = math.floor(front[index] * ratio + back[index] * (1 - ratio) + 0.5)
  end
  return ("#%02x%02x%02x"):format(channels[1], channels[2], channels[3])
end

local function token_settings(source, wanted_scope)
  local selected, selected_index
  for index, rule in ipairs(source.theme_definition.tokenColors) do
    local scopes = rule.scope
    if type(scopes) == "string" then
      if scopes == wanted_scope then
        selected, selected_index = rule.settings, index - 1
      end
    elseif type(scopes) == "table" then
      for _, scope in ipairs(scopes) do
        if scope == wanted_scope then
          selected, selected_index = rule.settings, index - 1
          break
        end
      end
    end
  end
  return selected, selected_index
end

local function default_token_settings(source)
  for index, rule in ipairs(source.theme_definition.tokenColors) do
    if rule.scope == nil then
      return rule.settings, index - 1
    end
  end
  fail("pinned source has no unscoped tokenColors rule")
end

local function parse_font_style(font_style, attrs)
  if type(font_style) ~= "string" then
    return
  end
  local seen = {}
  for style in font_style:gmatch("[^,%s]+") do
    style = vim.trim(style)
    seen[style] = true
  end
  attrs.bold = seen.bold == true
  attrs.italic = seen.italic == true
  attrs.underline = seen.underline == true
  attrs.strikethrough = seen.strikethrough == true
end

local function add_unique(values, value)
  for _, current in ipairs(values) do
    if current == value then
      return
    end
  end
  values[#values + 1] = value
end

local function sorted_keys(values)
  local result = {}
  for value in pairs(values or {}) do
    result[#result + 1] = value
  end
  table.sort(result)
  return result
end

local function compile(user_overrides, ui_colors)
  if user_overrides ~= nil and type(user_overrides) ~= "table" then
    fail("user_overrides must be a table or nil")
  end
  user_overrides = user_overrides or {}
  local source = load_source()
  -- Keep the pinned source immutable while applying theme-wide UI color choices.
  ui_colors = ui_colors or {}
  if type(ui_colors) ~= "table" then
    fail("ui_colors must be a table or nil")
  end
  local source_colors = vim.tbl_extend("force", source.theme_definition.colors, ui_colors)
  local overrides = {}
  local color_origins = {}
  local audit_info = {}
  local inherited_user_targets = {}

  local function put_group(group, attrs, origin_pointer)
    overrides[group] = vim.deepcopy(attrs)
    color_origins[group] = {}
    if origin_pointer and attrs.fg ~= nil then
      color_origins[group].fg = origin_pointer
    end
  end

  local function set_ui_attr(group, attribute, value, pointer)
    overrides[group] = overrides[group] or {}
    overrides[group][attribute] = value
    color_origins[group] = color_origins[group] or {}
    color_origins[group][attribute] = pointer
  end

  local function record_ui(key, targets, status, reason, attribute)
    local pointer = "/colors/" .. key
    local entry = audit_info[pointer] or { targets = {}, target_attributes = {}, status = status, reasons = {} }
    entry.status = status
    for _, target in ipairs(targets or {}) do
      add_unique(entry.targets, target)
      if attribute then
        entry.target_attributes[target] = attribute
      end
    end
    if reason then
      add_unique(entry.reasons, reason)
    end
    if ui_colors[key] then
      add_unique(
        entry.reasons,
        ("The theme-wide UI color choice replaces source %s with %s."):format(
          source.theme_definition.colors[key],
          ui_colors[key]
        )
      )
    end
    audit_info[pointer] = entry
  end

  local function set_ui(key, targets, attribute, options)
    options = options or {}
    local raw = source_colors[key]
    if raw == nil then
      fail("pinned source is missing colors." .. key)
    end
    local color, alpha = normalize_color(raw)
    if not color then
      fail("unsupported color literal at /colors/" .. key .. ": " .. raw)
    end
    local pointer = "/colors/" .. key
    local resolved_targets = {}
    if alpha ~= 255 then
      if alpha == 0 then
        record_ui(
          key,
          {},
          "sem_equivalente",
          options.reason or "The source color is fully transparent, so no highlight attribute is emitted."
        )
        return nil
      end
      if not options.background then
        fail("alpha color at /colors/" .. key .. " has no explicit container background")
      end
      color = composite(raw, options.background, alpha)
    end
    for _, group in ipairs(targets) do
      set_ui_attr(group, attribute, color, pointer)
      add_unique(resolved_targets, group)
    end
    record_ui(key, resolved_targets, options.status or "aproximado", options.reason, attribute)
    return color
  end

  local function final_background(group, fallback, visiting)
    visiting = visiting or {}
    if visiting[group] then
      return fallback
    end
    visiting[group] = true
    local custom = user_overrides[group]
    if type(custom) == "table" then
      if type(custom.bg) == "string" and custom.bg ~= "NONE" then
        return custom.bg
      end
      if type(custom.link) == "string" then
        return final_background(custom.link, fallback, visiting)
      end
      return fallback
    end
    local generated = overrides[group]
    if type(generated) == "table" then
      if type(generated.bg) == "string" and generated.bg ~= "NONE" then
        return generated.bg
      end
      if type(generated.link) == "string" then
        return final_background(generated.link, fallback, visiting)
      end
    end
    return fallback
  end

  local function set_scope(groups, wanted_scope, explicit_style)
    local settings, source_index = token_settings(source, wanted_scope)
    if not settings then
      fail("pinned source has no exact token scope " .. wanted_scope)
    end
    local selected_color = settings.foreground
    local color_index = source_index
    if not selected_color then
      local default_settings, default_index = default_token_settings(source)
      selected_color, color_index = default_settings.foreground, default_index
    end
    local color, alpha = normalize_color(selected_color)
    if not color or alpha ~= 255 then
      fail("token scope has unsupported foreground: " .. wanted_scope)
    end
    local attrs = { fg = color, bold = false, italic = false, underline = false }
    parse_font_style(settings.fontStyle, attrs)
    if explicit_style then
      for key, value in pairs(explicit_style) do
        attrs[key] = value
      end
    end
    local pointer = ("/tokenColors/%d/settings/foreground"):format(color_index)
    for _, group in ipairs(type(groups) == "table" and groups or { groups }) do
      put_group(group, attrs, pointer)
    end
  end

  local function set_default(groups, style)
    local settings = default_token_settings(source)
    local color, alpha = normalize_color(settings.foreground)
    if not color or alpha ~= 255 then
      fail("unscoped tokenColors rule has unsupported foreground")
    end
    local attrs = { fg = color, bold = false, italic = false, underline = false }
    if style then
      for key, value in pairs(style) do
        attrs[key] = value
      end
    end
    local pointer = "/tokenColors/0/settings/foreground"
    for _, group in ipairs(type(groups) == "table" and groups or { groups }) do
      local merged = vim.deepcopy(overrides[group] or {})
      for key, value in pairs(attrs) do
        merged[key] = value
      end
      overrides[group] = merged
      color_origins[group] = color_origins[group] or {}
      color_origins[group].fg = pointer
    end
  end

  -- Workbench colors mapped to highlight groups that have an active consumer.
  set_ui("editor.background", { "Normal", "SignColumn", "FoldColumn", "EndOfBuffer", "WinSeparator", "WinBar" }, "bg", {
    status = "aproximado",
    reason = "Applied to the editor surface and its attached native columns/bars.",
  })
  set_ui("foreground", { "Pmenu", "SnacksPicker" }, "fg", {
    status = "aproximado",
    reason = "Applied to the shared picker and completion-menu text; editor text uses the theme's unscoped token fallback.",
  })
  set_ui(
    "editorIndentGuide.background",
    { "IblIndent" },
    "fg",
    { status = "direto", reason = "Direct match for indent-blankline's active indent guide." }
  )
  set_ui(
    "editorIndentGuide.activeBackground",
    { "IblScope" },
    "fg",
    { status = "direto", reason = "Direct match for indent-blankline's active scope guide." }
  )
  set_ui(
    "editorRuler.foreground",
    { "ColorColumn" },
    "bg",
    { status = "direto", reason = "ColorColumn is the native vertical ruler highlight." }
  )
  set_ui(
    "editorLineNumber.foreground",
    { "LineNr", "CursorLineNr" },
    "fg",
    { status = "direto", reason = "Direct match for native line-number groups." }
  )
  set_ui("sideBar.background", { "SnacksPicker", "SnacksPickerBox" }, "bg", {
    status = "aproximado",
    reason = "Applied to the active Snacks picker/explorer surfaces used as Neovim's sidebar-like panels.",
  })
  set_ui(
    "sideBarSectionHeader.background",
    { "SnacksPickerTitle" },
    "bg",
    { reason = "Applied to the active Snacks picker section/title surface." }
  )
  set_ui(
    "editorSuggestWidget.background",
    { "Pmenu", "BlinkCmpMenu" },
    "bg",
    { reason = "Applied to native completion and the active Blink completion menu." }
  )
  set_ui("input.background", { "NormalFloat", "SnacksInputNormal" }, "bg", {
    status = "aproximado",
    reason = "Applied to Neovim floating inputs and menu surfaces.",
  })
  set_ui("input.foreground", { "NormalFloat", "SnacksInputNormal" }, "fg", {
    status = "aproximado",
    reason = "Applied to Neovim floating input text.",
  })
  set_ui(
    "list.activeSelectionBackground",
    { "PmenuSel", "BlinkCmpMenuSelection", "SnacksPickerListCursorLine" },
    "bg",
    {
      reason = "Applied to active rows in native, Blink, and Snacks lists.",
    }
  )
  set_ui(
    "list.activeSelectionForeground",
    { "PmenuSel", "BlinkCmpMenuSelection", "SnacksPickerListCursorLine" },
    "fg",
    {
      reason = "Applied to active rows in native, Blink, and Snacks lists.",
    }
  )
  set_ui(
    "list.inactiveSelectionBackground",
    { "Visual", "VisualNOS" },
    "bg",
    { reason = "A subtle background for native Visual/VisualNOS selections; syntax foregrounds remain unchanged." }
  )
  set_ui("list.inactiveSelectionForeground", {}, "fg", {
    status = "sem_equivalente",
    reason = "No active list consumer exposes a separate inactive-row foreground. Applying this list text color to editor selections would mask syntax highlighting.",
  })
  set_ui(
    "list.highlightForeground",
    { "SnacksPickerMatch", "BlinkCmpLabelMatch" },
    "fg",
    { reason = "Applied to search/completion match labels in active pickers." }
  )
  set_ui(
    "focusBorder",
    { "FloatBorder", "BlinkCmpMenuBorder" },
    "fg",
    { reason = "Applied to native and Blink completion-menu borders." }
  )
  set_ui(
    "panelTitle.activeForeground",
    { "WinBar" },
    "fg",
    { status = "aproximado", reason = "Applied to the native active window-bar title." }
  )
  set_ui(
    "panelTitle.inactiveForeground",
    { "WinBarNC" },
    "fg",
    { status = "aproximado", reason = "Applied to the native inactive window-bar title." }
  )
  set_ui("peekView.border", { "BlinkCmpDocBorder", "BlinkCmpSignatureHelpBorder" }, "fg", {
    status = "aproximado",
    reason = "Applied to active Blink documentation and signature-help borders, the closest active peek surfaces.",
  })
  set_ui("peekViewEditor.background", { "BlinkCmpDoc", "BlinkCmpSignatureHelp" }, "bg", {
    status = "aproximado",
    reason = "Applied to active Blink documentation and signature-help surfaces, the closest active peek surfaces.",
  })
  set_ui("pickerGroup.border", { "SnacksPickerBorder" }, "fg", {
    status = "aproximado",
    reason = "Applied to the active Snacks picker border; Neovim has no separate picker-group divider group.",
  })
  set_ui(
    "pickerGroup.foreground",
    { "SnacksPickerTitle" },
    "fg",
    { status = "aproximado", reason = "Applied to the active Snacks picker section/title text." }
  )
  set_ui(
    "gitDecoration.ignoredResourceForeground",
    { "SnacksPickerPathIgnored" },
    "fg",
    { status = "direto", reason = "Direct match for the active Snacks ignored-path highlight." }
  )
  set_ui("list.hoverBackground", {}, "bg", {
    status = "sem_equivalente",
    reason = "The active Neovim list consumers do not expose a separate hover-row background group.",
  })
  set_ui("list.hoverForeground", {}, "fg", {
    status = "sem_equivalente",
    reason = "The active Neovim list consumers do not expose a separate hover-row foreground group.",
  })

  -- Native statusline and tabline groups are stable consumers; Bufferline reads these groups.
  set_ui("statusBar.background", { "StatusLine" }, "bg", {
    status = "direto",
    reason = "Direct match for the native active statusline; lualine's auto theme derives from StatusLine.",
  })
  set_ui(
    "statusBar.noFolderBackground",
    { "StatusLineNC" },
    "bg",
    { reason = "Applied to the inactive/native statusline surface." }
  )
  set_ui("statusBar.foreground", { "StatusLine", "StatusLineNC" }, "fg", {
    status = "direto",
    reason = "Direct match for native statusline text; lualine's auto theme derives from StatusLine.",
  })
  local statusline_bg = final_background("StatusLine", source_colors["statusBar.background"])
  local prominent_color, prominent_alpha = normalize_color(source_colors["statusBarItem.prominentBackground"])
  local prominent_result = prominent_color
  if prominent_color and prominent_alpha and prominent_alpha > 0 and prominent_alpha < 255 then
    prominent_result = composite(source_colors["statusBarItem.prominentBackground"], statusline_bg, prominent_alpha)
  end
  record_ui(
    "statusBarItem.prominentBackground",
    {},
    "sem_equivalente",
    ("The source item background composites to %s over the final StatusLine background %s, but active lualine components expose no dedicated prominent-item surface."):format(
      prominent_result or "transparent",
      statusline_bg
    )
  )
  set_ui("statusBarItem.remoteBackground", {}, "bg", {
    status = "sem_equivalente",
    reason = "The remote status item has no separate highlight group and its source background has alpha 00, so no background is emitted.",
  })

  set_ui("editorGroupHeader.tabsBackground", { "TabLineFill" }, "bg", {
    status = "aproximado",
    reason = "Applied to the native tabline surface consumed by Bufferline's host groups.",
  })
  -- The source omits tab.activeBackground: the active tab inherits the editor surface.
  set_ui_attr(
    "TabLineSel",
    "bg",
    final_background("Normal", source_colors["editor.background"]),
    "/colors/editor.background"
  )
  record_ui(
    "editor.background",
    { "TabLineSel" },
    "aproximado",
    "The source omits tab.activeBackground; the selected tab inherits the final Normal background, including caller overrides.",
    "bg"
  )
  set_ui("tab.activeForeground", { "TabLineSel" }, "fg", {
    status = "aproximado",
    reason = "Applied to the native selected tabline group consumed by Bufferline's host groups.",
  })
  set_ui("tab.inactiveForeground", { "TabLine" }, "fg", {
    status = "aproximado",
    reason = "Applied to the native inactive tabline group consumed by Bufferline's host groups.",
  })
  set_ui("tab.inactiveBackground", { "TabLine" }, "bg", {
    status = "aproximado",
    reason = "Applied to the native inactive tabline group consumed by Bufferline's host groups.",
  })
  for _, key in ipairs({ "tab.border", "tab.activeBorder", "editorGroupHeader.tabsBorder" }) do
    record_ui(
      key,
      {},
      "sem_equivalente",
      "Neovim's native tabline and Bufferline do not expose a separate tab-border highlight group."
    )
  end

  set_ui("textLink.foreground", { "Underlined" }, "fg", {
    status = "aproximado",
    reason = "Applied to the native Underlined group; syntax links use their exact tokenColors scopes and caller overrides take precedence.",
  })
  set_ui(
    "inputOption.activeBackground",
    { "WildMenu" },
    "bg",
    { status = "aproximado", reason = "WildMenu is the native active command/input menu surface." }
  )

  -- VS Code surfaces with no distinct Neovim highlight counterpart preserve the plugin defaults.
  local no_equivalent = {
    ["activityBar.background"] = "Neovim has no separate activity-bar surface.",
    ["activityBar.foreground"] = "Neovim has no separate activity-bar text or icon group.",
    ["activityBarBadge.background"] = "Neovim has no activity-bar badge surface.",
    ["badge.background"] = "There is no shared badge surface among the active Neovim plugins.",
    ["badge.foreground"] = "There is no shared badge text group among the active Neovim plugins.",
    ["button.background"] = "Neovim has no shared button surface among the active plugins.",
    ["editor.lineHighlightBorder"] = "Neovim has no separate cursor-line border highlight group; mapping this border to a row background would change its meaning.",
    ["list.focusBackground"] = "The active Neovim list consumers do not expose a focused-row background separate from the selected-row group.",
    ["panelTitle.activeBorder"] = "Neovim has no separate active panel-title border highlight group.",
    ["progressBar.background"] = "The active Neovim UI has no shared progress-bar surface.",
    ["scrollbar.shadow"] = "nvim-scrollbar exposes a handle and marks but no scrollbar-shadow surface.",
    ["titleBar.activeBackground"] = "Neovim has no separate window title-bar surface.",
    ["titleBar.border"] = "Neovim has no separate window title-bar border surface.",
    ["terminal.ansiBrightBlack"] = "Neovim terminal ANSI colors are global terminal palette entries, not highlight groups accepted by this adapter.",
    ["statusBar.debuggingBackground"] = "The active statusline and lualine configuration expose no distinct debugging-background group.",
    ["statusBarItem.remoteForeground"] = "The remote status item has no separate foreground group; the shared value is already represented by statusBar.foreground.",
    ["textLink.activeForeground"] = "The active Neovim configuration has no separate active-link highlight group; applying this value to shared link groups would also recolor idle links.",
    ["debugIcon.continueForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.disconnectForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.pauseForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.restartForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.startForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.stepBackForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.stepIntoForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.stepOutForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.stepOverForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.stopForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.breakpointCurrentStackframeForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.breakpointDisabledForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.breakpointForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.breakpointStackframeForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
    ["debugIcon.breakpointUnverifiedForeground"] = "The active Neovim configuration has no debugger toolbar button highlight group.",
  }
  for key, reason in pairs(no_equivalent) do
    record_ui(key, {}, "sem_equivalente", reason)
  end

  -- VS Code symbolIcon colors apply to completion kind icons only, never to type text.
  for _, key in ipairs({
    "symbolIcon.classForeground",
    "symbolIcon.enumeratorForeground",
    "symbolIcon.eventForeground",
  }) do
    local icon_type = key == "symbolIcon.classForeground" and "Class"
      or key == "symbolIcon.enumeratorForeground" and "Enum"
      or "Event"
    set_ui(
      key,
      { "BlinkCmpKind" .. icon_type },
      "fg",
      { status = "direto", reason = "Applied only to the corresponding active Blink completion kind icon." }
    )
  end
  for _, key in ipairs({
    "symbolIcon.methodForeground",
    "symbolIcon.constructorForeground",
    "symbolIcon.functionForeground",
  }) do
    local icon_type = key == "symbolIcon.methodForeground" and "Method"
      or key == "symbolIcon.constructorForeground" and "Constructor"
      or "Function"
    set_ui(
      key,
      { "BlinkCmpKind" .. icon_type },
      "fg",
      { status = "direto", reason = "Applied only to the corresponding active Blink completion kind icon." }
    )
  end
  for _, key in ipairs({
    "symbolIcon.fieldForeground",
    "symbolIcon.interfaceForeground",
    "symbolIcon.variableForeground",
    "symbolIcon.enumeratorMemberForeground",
  }) do
    local icon_type = key == "symbolIcon.fieldForeground" and "Field"
      or key == "symbolIcon.interfaceForeground" and "Interface"
      or key == "symbolIcon.variableForeground" and "Variable"
      or "EnumMember"
    set_ui(
      key,
      { "BlinkCmpKind" .. icon_type },
      "fg",
      { status = "direto", reason = "Applied only to the corresponding active Blink completion kind icon." }
    )
  end

  -- Composite diff colors over the final editor background, including caller overrides.
  local normal_bg = final_background("Normal", source_colors["editor.background"])
  set_ui("diffEditor.insertedTextBackground", { "DiffAdd" }, "bg", {
    background = normal_bg,
    reason = "Alpha-composited over the final Normal background before assigning DiffAdd.",
  })
  set_ui("diffEditor.removedTextBackground", { "DiffDelete" }, "bg", {
    background = normal_bg,
    reason = "Alpha-composited over the final Normal background before assigning DiffDelete.",
  })

  -- Syntax categories use exact source scopes. This intentionally does not implement TextMate selector inheritance.
  set_default({ "Normal", "@module", "@namespace", "@lsp.type.namespace" })
  set_scope({ "Operator", "@operator", "@lsp.type.operator" }, "keyword")
  set_scope({
    "Function",
    "@function",
    "@function.call",
    "@function.method",
    "@method",
    "@method.call",
    "@constructor",
    "@lsp.type.function",
    "@lsp.type.method",
  }, "entity.name.function")
  set_scope({ "Special", "@function.builtin", "@lsp.typemod.function.defaultLibrary" }, "support.function")

  set_scope({ "@text.emphasis", "@markup.italic", "markdownItalic" }, "markup.italic.markdown", { italic = true })
  set_scope({
    "@markup.heading",
    "@markup.strong",
    "@text.strong",
    "markdownBold",
    "markdownH1",
    "markdownH2",
    "markdownH3",
    "markdownH4",
    "markdownH5",
    "markdownH6",
    "markdownHeadingDelimiter",
    "RenderMarkdownH1",
    "RenderMarkdownH2",
    "RenderMarkdownH3",
    "RenderMarkdownH4",
    "RenderMarkdownH5",
    "RenderMarkdownH6",
  }, "markup.heading.markdown", { bold = true })
  set_scope({ "markdownBoldItalic" }, "markup.heading.markdown", { bold = true, italic = true })
  set_scope({ "@markup.link", "@markup.link.label", "@text.uri" }, "meta.link.inline.markdown")
  set_scope({
    "@markup.raw",
    "@text.literal",
    "markdownCode",
    "markdownCodeBlock",
    "markdownCodeDelimiter",
    "RenderMarkdownCodeInfo",
    "RenderMarkdownCodeFallback",
  }, "markup.fenced_code")
  -- These extmarks cover entire code rows above injected Tree-sitter captures.
  -- A foreground here would replace the syntax colors in LSP documentation.
  set_ui_attr(
    "RenderMarkdownCode",
    "bg",
    final_background("NormalFloat", source_colors["input.background"]),
    "/colors/input.background"
  )
  record_ui(
    "input.background",
    { "RenderMarkdownCode" },
    "aproximado",
    "Rendered code blocks inherit the final NormalFloat background, including caller overrides, without a foreground that would mask injected syntax colors.",
    "bg"
  )
  overrides.RenderMarkdownCodeBorder = { link = "RenderMarkdownCode" }
  set_scope({ "RenderMarkdownCodeInline" }, "markup.inline")
  set_scope({
    "Comment",
    "Todo",
    "Done",
    "@comment",
    "@comment.todo",
    "@comment.note",
    "@comment.warning",
    "@comment.error",
    "@comment.documentation",
    "@lsp.type.comment",
  }, "comment")
  set_scope({ "@string.documentation" }, "string.quoted.docstring.multi")
  set_scope({
    "Identifier",
    "@variable",
    "@variable.builtin",
    "@variable.member",
    "@field",
    "@property",
    "@lsp.type.variable",
    "@lsp.type.property",
    "@lsp.type.field",
    "@lsp.type.event",
    "@lsp.type.enumMember",
  }, "variable.other.object")
  set_scope({ "@variable.access" }, "variable.other.object")
  put_group("@variable.standalone", { link = "@variable.declaration" }, nil)
  set_scope({ "Number", "Float", "@number", "@number.float", "@float", "@lsp.type.number" }, "constant.numeric")
  -- The source has no declaration rule; reuse its off-white for the requested distinction.
  set_scope({
    "@variable.declaration",
    "@lsp.typemod.variable.declaration",
    "@lsp.typemod.variable.definition",
    "@lsp.typemod.field.declaration",
    "@lsp.typemod.field.definition",
    "@lsp.typemod.property.declaration",
    "@lsp.typemod.property.definition",
  }, "constant.numeric")
  set_scope({
    "Boolean",
    "Constant",
    "@boolean",
    "@constant",
    "@constant.builtin",
    "@constant.macro",
    "@lsp.type.boolean",
    "@lsp.type.enumMember",
  }, "constant.language")
  set_scope({
    "Keyword",
    "Statement",
    "Conditional",
    "Repeat",
    "Label",
    "Exception",
    "StorageClass",
    "PreProc",
    "Include",
    "Define",
    "PreCondit",
    "@keyword",
    "@keyword.conditional",
    "@keyword.debug",
    "@keyword.directive",
    "@keyword.directive.define",
    "@keyword.exception",
    "@keyword.function",
    "@keyword.import",
    "@keyword.operator",
    "@keyword.repeat",
    "@keyword.return",
    "@keyword.storage",
    "@conditional",
    "@repeat",
    "@debug",
    "@label",
    "@include",
    "@exception",
    "@storageclass",
    "@type.builtin",
    "@type.qualifier",
    "@lsp.type.keyword",
    "@lsp.type.modifier",
  }, "keyword")
  set_scope({ "@parameter", "@variable.parameter", "@lsp.type.parameter" }, "variable.parameter.function")
  set_scope({
    "Type",
    "Structure",
    "Typedef",
    "@type",
    "@type.definition",
    "@structure",
    "@lsp.type.class",
    "@lsp.type.interface",
    "@lsp.type.struct",
    "@lsp.type.enum",
    "@lsp.type.type",
    "@lsp.type.typeParameter",
  }, "entity.name.type")
  set_scope({ "String", "Character", "@string", "@lsp.type.string" }, "string.quoted")
  set_scope({ "@string.regex", "@string.regexp", "@lsp.type.regexp" }, "string.regexp")
  set_scope({ "@string.template" }, "string.template")
  set_scope({ "@string.special.url" }, "markup.underline.link")
  set_scope({ "@tag", "xmlTagName", "xmlNamespace", "htmlTagName", "htmlSpecialTagName" }, "entity.name.tag")
  set_scope({ "@tag.attribute" }, "entity.other.attribute-name")
  set_scope({ "@string.special.key" }, "support.type.property-name.json")
  set_scope({
    "Delimiter",
    "@punctuation",
    "@punctuation.delimiter",
    "@punctuation.bracket",
    "@punctuation.special",
    "@tag.delimiter.html",
    "@tag.delimiter.xml",
    "xmlTag",
    "xmlEndTag",
    "htmlTag",
    "htmlEndTag",
    "htmlTagN",
  }, "punctuation.separator")
  set_scope({ "@punctuation.special" }, "punctuation.definition.template-expression")
  set_scope({
    "@markup.list",
    "@markup.list.checked",
    "@markup.list.unchecked",
    "markdownListMarker",
    "markdownOrderedListMarker",
  }, "beginning.punctuation.definition.list.markdown")
  set_scope({ "markdownUrl", "markdownLinkText", "RenderMarkdownLink" }, "markup.underline.link")
  set_scope({ "markdownHeadingDelimiter" }, "punctuation.definition.metadata.markdown")
  set_scope(
    { "markdownLinkDelimiter", "markdownLinkTextDelimiter", "markdownUrlDelimiter" },
    "punctuation.definition.string.begin.markdown"
  )
  -- Semantic modifiers stay out of the base category; only the specified modifiers add color/style.
  set_scope({
    "@lsp.typemod.class.defaultLibrary",
    "@lsp.typemod.interface.defaultLibrary",
    "@lsp.typemod.struct.defaultLibrary",
    "@lsp.typemod.enum.defaultLibrary",
    "@lsp.typemod.type.defaultLibrary",
  }, "support")
  set_scope(
    { "@lsp.typemod.variable.readonly", "@lsp.typemod.property.readonly", "@lsp.typemod.field.readonly" },
    "variable.other.constant"
  )
  put_group("DiagnosticDeprecated", { strikethrough = true }, nil)
  put_group("@lsp.mod.deprecated", { strikethrough = true }, nil)

  local function inherit_user_parent(parent, children)
    if user_overrides[parent] == nil then
      return
    end
    for _, child in ipairs(children) do
      overrides[child] = { link = parent }
      color_origins[child] = {}
      inherited_user_targets[child] = parent
    end
  end

  -- Keep established plugin inheritance when a caller overrides the parent surface.
  inherit_user_parent("@variable.declaration", {
    "@lsp.typemod.variable.declaration",
    "@lsp.typemod.variable.definition",
    "@lsp.typemod.field.declaration",
    "@lsp.typemod.field.definition",
    "@lsp.typemod.property.declaration",
    "@lsp.typemod.property.definition",
  })
  inherit_user_parent("Pmenu", { "BlinkCmpMenu", "BlinkCmpMenuBorder" })
  inherit_user_parent("NormalFloat", {
    "SnacksInputNormal",
    "BlinkCmpDoc",
    "BlinkCmpDocBorder",
    "BlinkCmpDocSeparator",
    "BlinkCmpSignatureHelp",
    "BlinkCmpSignatureHelpBorder",
  })
  inherit_user_parent("SnacksPicker", {
    "SnacksPickerBox",
    "SnacksPickerInput",
    "SnacksPickerList",
    "SnacksPickerTitle",
    "SnacksPickerBorder",
  })

  -- Replace each generated group definition as a whole, preserving caller values and input immutability.
  for group, definition in pairs(user_overrides) do
    overrides[group] = vim.deepcopy(definition)
  end

  return overrides, source, color_origins, audit_info, inherited_user_targets
end

local token_reasons = {
  [0] = "The unscoped tokenColors foreground is used for Normal text and as the fallback for module/namespace and unscoped syntax captures.",
  [1] = "Exact support.function maps to shared builtin-function groups; accessor operators and compound TextMate selectors have no dedicated universal capture equivalent.",
  [3] = "Exact Markdown heading/strong scopes preserve both the source foreground and bold style.",
  [5] = "The exact inline-link scope is mapped to link captures; caller link overrides take precedence by complete group replacement.",
  [6] = "Exact fenced/inline Markdown scopes map to code captures; generic TextMate string ancestry is not inferred.",
  [7] = "Exact comment and docstring scopes map to plain comment captures with italic disabled.",
  [8] = "Exact variable/property scopes map to shared identifier and semantic-token groups.",
  [9] = "Exact numeric and JSON property-name scopes map to number/key captures. The requested declaration/reference distinction reuses this off-white for variable declarations; the source has no explicit declaration-color rule. entity.other.attribute-name is shadowed by later tokenColors/12.",
  [10] = "Exact keyword/storage scopes map to shared control and primitive captures; keyword.other.template is shadowed by later tokenColors/13, and key-value punctuation has no dedicated shared capture.",
  [11] = "The exact parameter scope maps to parameter captures, including semantic tokens.",
  [12] = "Exact type/function/attribute scopes map to shared syntax and semantic groups; repeated entity.other.attribute-name resolves to this later purple value.",
  [13] = "Exact quoted/template/regexp/tag scopes map to shared code captures and legacy HTML/XML tag names; keyword.other.template has no separate shared capture.",
  [14] = "The source info log-token has no active Neovim log-token consumer; it is not mapped to LSP diagnostics.",
  [15] = "The source warning log-token has no active Neovim log-token consumer; it is not mapped to LSP diagnostics.",
  [16] = "The source error log-token has no active Neovim log-token consumer; it is not mapped to LSP diagnostics.",
  [17] = "The source debug log-token has no active Neovim log-token consumer; it is not mapped to LSP diagnostics, and deprecated tokens receive style only.",
  [18] = "Exact punctuation scopes map to shared delimiter captures, with HTML/XML tag delimiters using the same gray; specialized compound scopes without a universal capture are not interpreted.",
  [19] = "The exact custom Markdown-link scope maps to link groups; caller link overrides take precedence by complete group replacement.",
  [20] = "The exact Markdown list marker scope maps to Markdown list captures and legacy groups.",
  [21] = "The exact Markdown metadata punctuation scope maps to the active Markdown heading delimiter group.",
  [22] = "Exact Markdown string-bracket scopes map to link-label delimiters; the caller's link-label override takes precedence when supplied.",
}

local function audit_records(user_overrides, ui_colors)
  local overrides, source, color_origins, audit_info, inherited_user_targets = compile(user_overrides, ui_colors)
  local records = {}
  for _, item in ipairs(source.color_key_values) do
    local token_index = item.json_pointer:match("^/tokenColors/(%d+)/settings/foreground$")
    local targets, status, reason = {}, nil, nil
    if token_index then
      local wanted_pointer = item.json_pointer
      for group, origins in pairs(color_origins) do
        for _, origin_pointer in pairs(origins) do
          if origin_pointer == wanted_pointer then
            add_unique(targets, group)
            break
          end
        end
      end
      table.sort(targets)
      local index = tonumber(token_index)
      if #targets > 0 then
        status = "aproximado"
        reason = token_reasons[index] or "The exact source scope maps to a shared Neovim highlight group."
      else
        status = "sem_equivalente"
        reason = token_reasons[index] or "No active Neovim capture corresponds to this exact source scope."
      end
    else
      local info = audit_info[item.json_pointer]
      if info then
        local shadowed = {}
        local inherited = {}
        for _, target in ipairs(info.targets) do
          local attribute = info.target_attributes[target]
          local origins = color_origins[target]
          if inherited_user_targets[target] then
            add_unique(targets, target)
            add_unique(inherited, ("%s inherits %s"):format(target, inherited_user_targets[target]))
          elseif origins and origins[attribute] == item.json_pointer then
            add_unique(targets, target)
          elseif origins and origins[attribute] then
            add_unique(targets, target)
            add_unique(shadowed, ("%s.%s uses %s"):format(target, attribute, origins[attribute]))
          elseif user_overrides and user_overrides[target] ~= nil then
            add_unique(targets, target)
          end
        end
        table.sort(targets)
        status = info.status
        local reasons = vim.deepcopy(info.reasons)
        if #inherited > 0 then
          table.sort(inherited)
          add_unique(
            reasons,
            "These consumers inherit caller-controlled parent groups: " .. table.concat(inherited, ", ") .. "."
          )
        end
        if #shadowed > 0 then
          table.sort(shadowed)
          add_unique(
            reasons,
            "Some targets are shadowed by later source assignments: " .. table.concat(shadowed, ", ") .. "."
          )
        end
        reason = table.concat(reasons, " ")
      else
        status = "sem_equivalente"
        reason = "No active Neovim highlight group corresponds to this workbench color."
      end
    end

    local user_overridden_targets = {}
    local directly_replaced = {}
    local inherited_replacements = {}
    for _, group in ipairs(targets) do
      if user_overrides and user_overrides[group] ~= nil then
        add_unique(user_overridden_targets, group)
        add_unique(directly_replaced, group)
      elseif
        inherited_user_targets[group]
        and user_overrides
        and user_overrides[inherited_user_targets[group]] ~= nil
      then
        add_unique(user_overridden_targets, group)
        add_unique(inherited_replacements, ("%s inherits %s"):format(group, inherited_user_targets[group]))
      end
    end
    table.sort(user_overridden_targets)
    local reason_suffix = {}
    if #directly_replaced > 0 then
      table.sort(directly_replaced)
      add_unique(
        reason_suffix,
        "Caller definitions replace these complete groups: " .. table.concat(directly_replaced, ", ") .. "."
      )
    end
    if #inherited_replacements > 0 then
      table.sort(inherited_replacements)
      add_unique(
        reason_suffix,
        "Caller overrides propagate through these restored links: " .. table.concat(inherited_replacements, ", ") .. "."
      )
    end
    if #reason_suffix > 0 then
      reason = reason and (reason .. " " .. table.concat(reason_suffix, " ")) or table.concat(reason_suffix, " ")
    end
    records[#records + 1] = {
      json_pointer = item.json_pointer,
      source_value = item.value,
      status = status,
      targets = targets,
      reason = reason,
      user_overridden_targets = user_overridden_targets,
    }
  end
  return records
end

function M.build_overrides(user_overrides, ui_colors)
  local overrides = compile(user_overrides, ui_colors)
  return overrides
end

function M.audit(user_overrides, ui_colors)
  return audit_records(user_overrides, ui_colors)
end

return M
