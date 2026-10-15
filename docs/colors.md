# Color mapping

The complete pinned VS Code Min Dark definition and 105 color occurrences are bundled in `lua/min-theme/resources/min-dark-vscode-color-map.json`. Source: `miguelsolorio/min-theme`, commit `dd796c3f294daecfb7f10ed277ffdc30517d59cf`, `themes/min-dark.json`; original SHA256 `617a7949326293695e7cd1d0ad169ddb96ebf34929e8bb88bf3f79b40e2992c5`.

The pure compiler in `lua/min-theme/vscode.lua` maps explicit TextMate scopes and native UI counterparts. Its audit records every source key: direct match, approximation, or no Neovim equivalent. Unsupported VS Code surfaces are documented rather than assigned to unrelated editor categories. RGBA values are composited over their container. Symbol icon colors affect completion icons, not type text.

The fork's default choices in `defaults.lua` supersede source UI colors: editor background `#121212`, foreground `#cfcfcf`, floating/picker background `#121212`, native autocomplete background `#161616`, visual background `#2a2a2a`, current line `#181818` and link blue `#368cfc`. Contextual declarations/standalone variables use the editor foreground, not the source numeric foreground `#f8f8f8`. The static semantic declaration modifiers stay blue to support a uniform fallback.

`vscode.audit()` describes the source adaptation; pass `require("min-theme.defaults").get(colors)` to include the fork's surface choices. The public `setup().overrides` merge occurs afterward and retains inherited attributes for partial definitions. An explicit link replaces the group.

The theme-owned role engine walks native ASTs with lexical binding scopes. It does not modify global queries or native semantic-token namespaces. Tree-sitter overlays use priority 101, below native semantic tokens; authoritative LSP variables use 128, declarations 129 and parameters 130. Without a usable parser, semantic parameter identity and declaration modifiers can still be used; unknown variable expressions remain blue. Edits discard stale overlays until fresh classification is available.

Reloading the theme restores and reinstalls integrations. Switching colorschemes removes role namespaces and scheduled updates. Bufferline uses static theme highlights; its public highlight references keep generated icon backgrounds aligned with `TabLine` and `TabLineSel` (see the README setup example). No plugin functions are wrapped, and no plugin or LSP configuration is mutated.

## Complete source audit

| Source pointer | Original value | Mapping | Neovim groups |
| --- | --- | --- | --- |
| `/colors/editorIndentGuide.activeBackground` | `#383838` | direto | `IblScope` |
| `/colors/editorIndentGuide.background` | `#2A2A2A` | direto | `IblIndent` |
| `/colors/editorRuler.foreground` | `#2A2A2A` | direto | `ColorColumn` |
| `/colors/editorLineNumber.foreground` | `#727272` | direto | `CursorLineNr`, `LineNr` |
| `/colors/activityBar.background` | `#1A1A1A` | sem_equivalente |  |
| `/colors/activityBar.foreground` | `#7D7D7D` | sem_equivalente |  |
| `/colors/activityBarBadge.background` | `#383838` | sem_equivalente |  |
| `/colors/badge.background` | `#383838` | sem_equivalente |  |
| `/colors/badge.foreground` | `#C1C1C1` | sem_equivalente |  |
| `/colors/button.background` | `#333` | sem_equivalente |  |
| `/colors/editor.background` | `#1f1f1f` | aproximado | `EndOfBuffer`, `FoldColumn`, `Normal`, `SignColumn`, `TabLineSel`, `WinBar`, `WinSeparator` |
| `/colors/editor.lineHighlightBorder` | `#303030` | sem_equivalente |  |
| `/colors/editorGroupHeader.tabsBackground` | `#1A1A1A` | aproximado | `TabLineFill` |
| `/colors/editorGroupHeader.tabsBorder` | `#1A1A1A` | sem_equivalente |  |
| `/colors/editorSuggestWidget.background` | `#1A1A1A` | aproximado | `BlinkCmpMenu`, `Pmenu` |
| `/colors/focusBorder` | `#444` | aproximado | `BlinkCmpMenuBorder`, `FloatBorder` |
| `/colors/foreground` | `#888888` | aproximado | `Pmenu`, `SnacksPicker` |
| `/colors/gitDecoration.ignoredResourceForeground` | `#444444` | direto | `SnacksPickerPathIgnored` |
| `/colors/input.background` | `#2A2A2A` | aproximado | `NormalFloat`, `RenderMarkdownCode`, `SnacksInputNormal` |
| `/colors/input.foreground` | `#E0E0E0` | aproximado | `NormalFloat`, `SnacksInputNormal` |
| `/colors/list.activeSelectionBackground` | `#212121` | aproximado | `BlinkCmpMenuSelection`, `PmenuSel`, `SnacksPickerListCursorLine` |
| `/colors/list.activeSelectionForeground` | `#F5F5F5` | aproximado | `BlinkCmpMenuSelection`, `PmenuSel`, `SnacksPickerListCursorLine` |
| `/colors/list.focusBackground` | `#292929` | sem_equivalente |  |
| `/colors/list.highlightForeground` | `#EAEAEA` | aproximado | `BlinkCmpLabelMatch`, `SnacksPickerMatch` |
| `/colors/list.hoverBackground` | `#262626` | sem_equivalente |  |
| `/colors/list.hoverForeground` | `#9E9E9E` | sem_equivalente |  |
| `/colors/list.inactiveSelectionBackground` | `#212121` | aproximado | `Visual`, `VisualNOS` |
| `/colors/list.inactiveSelectionForeground` | `#F5F5F5` | sem_equivalente |  |
| `/colors/panelTitle.activeBorder` | `#1f1f1f` | sem_equivalente |  |
| `/colors/panelTitle.activeForeground` | `#FAFAFA` | aproximado | `WinBar` |
| `/colors/panelTitle.inactiveForeground` | `#484848` | aproximado | `WinBarNC` |
| `/colors/peekView.border` | `#444` | aproximado | `BlinkCmpDocBorder`, `BlinkCmpSignatureHelpBorder` |
| `/colors/peekViewEditor.background` | `#242424` | aproximado | `BlinkCmpDoc`, `BlinkCmpSignatureHelp` |
| `/colors/pickerGroup.border` | `#363636` | aproximado | `SnacksPickerBorder` |
| `/colors/pickerGroup.foreground` | `#EAEAEA` | aproximado | `SnacksPickerTitle` |
| `/colors/progressBar.background` | `#FAFAFA` | sem_equivalente |  |
| `/colors/scrollbar.shadow` | `#1f1f1f` | sem_equivalente |  |
| `/colors/sideBar.background` | `#1A1A1A` | aproximado | `SnacksPicker`, `SnacksPickerBox` |
| `/colors/sideBarSectionHeader.background` | `#202020` | aproximado | `SnacksPickerTitle` |
| `/colors/statusBar.background` | `#1A1A1A` | direto | `StatusLine` |
| `/colors/statusBar.debuggingBackground` | `#1A1A1A` | sem_equivalente |  |
| `/colors/statusBar.foreground` | `#7E7E7E` | direto | `StatusLine`, `StatusLineNC` |
| `/colors/statusBar.noFolderBackground` | `#1A1A1A` | aproximado | `StatusLineNC` |
| `/colors/statusBarItem.remoteForeground` | `#7E7E7E` | sem_equivalente |  |
| `/colors/statusBarItem.remoteBackground` | `#1a1a1a00` | sem_equivalente |  |
| `/colors/statusBarItem.prominentBackground` | `#fafafa1a` | sem_equivalente |  |
| `/colors/tab.activeBorder` | `#1e1e1e` | sem_equivalente |  |
| `/colors/tab.activeForeground` | `#FAFAFA` | aproximado | `TabLineSel` |
| `/colors/tab.border` | `#1A1A1A` | sem_equivalente |  |
| `/colors/tab.inactiveBackground` | `#1A1A1A` | aproximado | `TabLine` |
| `/colors/tab.inactiveForeground` | `#727272` | aproximado | `TabLine` |
| `/colors/textLink.foreground` | `#CCC` | aproximado | `Underlined` |
| `/colors/textLink.activeForeground` | `#fafafa` | sem_equivalente |  |
| `/colors/titleBar.activeBackground` | `#1A1A1A` | sem_equivalente |  |
| `/colors/titleBar.border` | `#00000000` | sem_equivalente |  |
| `/colors/terminal.ansiBrightBlack` | `#5c5c5c` | sem_equivalente |  |
| `/colors/inputOption.activeBackground` | `#3a3a3a` | aproximado | `WildMenu` |
| `/colors/debugIcon.continueForeground` | `#FF7A84` | sem_equivalente |  |
| `/colors/debugIcon.disconnectForeground` | `#FF7A84` | sem_equivalente |  |
| `/colors/debugIcon.pauseForeground` | `#FF7A84` | sem_equivalente |  |
| `/colors/debugIcon.restartForeground` | `#79b8ff` | sem_equivalente |  |
| `/colors/debugIcon.startForeground` | `#79b8ff` | sem_equivalente |  |
| `/colors/debugIcon.stepBackForeground` | `#FF7A84` | sem_equivalente |  |
| `/colors/debugIcon.stepIntoForeground` | `#FF7A84` | sem_equivalente |  |
| `/colors/debugIcon.stepOutForeground` | `#FF7A84` | sem_equivalente |  |
| `/colors/debugIcon.stepOverForeground` | `#FF7A84` | sem_equivalente |  |
| `/colors/debugIcon.stopForeground` | `#79b8ff` | sem_equivalente |  |
| `/colors/debugIcon.breakpointCurrentStackframeForeground` | `#79b8ff` | sem_equivalente |  |
| `/colors/debugIcon.breakpointDisabledForeground` | `#848484` | sem_equivalente |  |
| `/colors/debugIcon.breakpointForeground` | `#FF7A84` | sem_equivalente |  |
| `/colors/debugIcon.breakpointStackframeForeground` | `#79b8ff` | sem_equivalente |  |
| `/colors/debugIcon.breakpointUnverifiedForeground` | `#848484` | sem_equivalente |  |
| `/colors/symbolIcon.classForeground` | `#FF9800` | direto | `BlinkCmpKindClass` |
| `/colors/symbolIcon.enumeratorForeground` | `#FF9800` | direto | `BlinkCmpKindEnum` |
| `/colors/symbolIcon.eventForeground` | `#FF9800` | direto | `BlinkCmpKindEvent` |
| `/colors/symbolIcon.methodForeground` | `#b392f0` | direto | `BlinkCmpKindMethod` |
| `/colors/symbolIcon.constructorForeground` | `#b392f0` | direto | `BlinkCmpKindConstructor` |
| `/colors/symbolIcon.functionForeground` | `#b392f0` | direto | `BlinkCmpKindFunction` |
| `/colors/symbolIcon.fieldForeground` | `#79b8ff` | direto | `BlinkCmpKindField` |
| `/colors/symbolIcon.interfaceForeground` | `#79b8ff` | direto | `BlinkCmpKindInterface` |
| `/colors/symbolIcon.variableForeground` | `#79b8ff` | direto | `BlinkCmpKindVariable` |
| `/colors/symbolIcon.enumeratorMemberForeground` | `#79b8ff` | direto | `BlinkCmpKindEnumMember` |
| `/colors/diffEditor.insertedTextBackground` | `#3a632a4b` | aproximado | `DiffAdd` |
| `/colors/diffEditor.removedTextBackground` | `#88063852` | aproximado | `DiffDelete` |
| `/tokenColors/0/settings/foreground` | `#b392f0` | aproximado | `@lsp.type.namespace`, `@markup.italic`, `@module`, `@namespace`, `@text.emphasis`, `Normal`, `markdownItalic` |
| `/tokenColors/1/settings/foreground` | `#b392f0` | aproximado | `@function.builtin`, `@lsp.typemod.function.defaultLibrary`, `Special` |
| `/tokenColors/3/settings/foreground` | `#FF7A84` | aproximado | `@markup.heading`, `@markup.strong`, `@text.strong`, `RenderMarkdownH1`, `RenderMarkdownH2`, `RenderMarkdownH3`, `RenderMarkdownH4`, `RenderMarkdownH5`, `RenderMarkdownH6`, `markdownBold`, `markdownBoldItalic`, `markdownH1`, `markdownH2`, `markdownH3`, `markdownH4`, `markdownH5`, `markdownH6` |
| `/tokenColors/5/settings/foreground` | `#1976D2` | aproximado | `@markup.link`, `@markup.link.label`, `@text.uri` |
| `/tokenColors/6/settings/foreground` | `#9db1c5` | aproximado | `@markup.raw`, `@text.literal`, `RenderMarkdownCodeFallback`, `RenderMarkdownCodeInfo`, `RenderMarkdownCodeInline`, `markdownCode`, `markdownCodeBlock`, `markdownCodeDelimiter` |
| `/tokenColors/7/settings/foreground` | `#6b737c` | aproximado | `@comment`, `@comment.documentation`, `@comment.error`, `@comment.note`, `@comment.todo`, `@comment.warning`, `@lsp.type.comment`, `@string.documentation`, `Comment`, `Done`, `Todo` |
| `/tokenColors/8/settings/foreground` | `#79b8ff` | aproximado | `@boolean`, `@constant`, `@constant.builtin`, `@constant.macro`, `@field`, `@lsp.type.boolean`, `@lsp.type.enumMember`, `@lsp.type.event`, `@lsp.type.field`, `@lsp.type.property`, `@lsp.type.variable`, `@lsp.typemod.class.defaultLibrary`, `@lsp.typemod.enum.defaultLibrary`, `@lsp.typemod.field.readonly`, `@lsp.typemod.interface.defaultLibrary`, `@lsp.typemod.property.readonly`, `@lsp.typemod.struct.defaultLibrary`, `@lsp.typemod.type.defaultLibrary`, `@lsp.typemod.variable.readonly`, `@property`, `@variable`, `@variable.access`, `@variable.builtin`, `@variable.member`, `Boolean`, `Constant`, `Identifier` |
| `/tokenColors/9/settings/foreground` | `#f8f8f8` | aproximado | `@float`, `@lsp.type.number`, `@number`, `@number.float`, `@string.special.key`, `@variable.declaration`, `Float`, `Number` |
| `/tokenColors/10/settings/foreground` | `#f97583` | aproximado | `@conditional`, `@debug`, `@exception`, `@include`, `@keyword`, `@keyword.conditional`, `@keyword.debug`, `@keyword.directive`, `@keyword.directive.define`, `@keyword.exception`, `@keyword.function`, `@keyword.import`, `@keyword.operator`, `@keyword.repeat`, `@keyword.return`, `@keyword.storage`, `@label`, `@lsp.type.keyword`, `@lsp.type.modifier`, `@lsp.type.operator`, `@operator`, `@punctuation.special`, `@repeat`, `@storageclass`, `@type.builtin`, `@type.qualifier`, `Conditional`, `Define`, `Exception`, `Include`, `Keyword`, `Label`, `Operator`, `PreCondit`, `PreProc`, `Repeat`, `Statement`, `StorageClass` |
| `/tokenColors/11/settings/foreground` | `#FF9800` | aproximado | `@lsp.type.parameter`, `@parameter`, `@variable.parameter` |
| `/tokenColors/12/settings/foreground` | `#b392f0` | aproximado | `@constructor`, `@function`, `@function.call`, `@function.method`, `@lsp.type.class`, `@lsp.type.enum`, `@lsp.type.function`, `@lsp.type.interface`, `@lsp.type.method`, `@lsp.type.struct`, `@lsp.type.type`, `@lsp.type.typeParameter`, `@method`, `@method.call`, `@structure`, `@tag.attribute`, `@type`, `@type.definition`, `Function`, `Structure`, `Type`, `Typedef` |
| `/tokenColors/13/settings/foreground` | `#ffab70` | aproximado | `@lsp.type.regexp`, `@lsp.type.string`, `@string`, `@string.regex`, `@string.regexp`, `@string.template`, `@tag`, `Character`, `String`, `htmlSpecialTagName`, `htmlTagName`, `xmlNamespace`, `xmlTagName` |
| `/tokenColors/14/settings/foreground` | `#316bcd` | sem_equivalente |  |
| `/tokenColors/15/settings/foreground` | `#cd9731` | sem_equivalente |  |
| `/tokenColors/16/settings/foreground` | `#cd3131` | sem_equivalente |  |
| `/tokenColors/17/settings/foreground` | `#800080` | sem_equivalente |  |
| `/tokenColors/18/settings/foreground` | `#bbbbbb` | aproximado | `@punctuation`, `@punctuation.bracket`, `@punctuation.delimiter`, `@tag.delimiter.html`, `@tag.delimiter.xml`, `Delimiter`, `htmlEndTag`, `htmlTag`, `htmlTagN`, `xmlEndTag`, `xmlTag` |
| `/tokenColors/19/settings/foreground` | `#ffab70` | aproximado | `@string.special.url`, `RenderMarkdownLink`, `markdownLinkText`, `markdownUrl` |
| `/tokenColors/20/settings/foreground` | `#FF7A84` | aproximado | `@markup.list`, `@markup.list.checked`, `@markup.list.unchecked`, `markdownListMarker`, `markdownOrderedListMarker` |
| `/tokenColors/21/settings/foreground` | `#ffab70` | aproximado | `markdownHeadingDelimiter` |
| `/tokenColors/22/settings/foreground` | `#79b8ff` | aproximado | `markdownLinkDelimiter`, `markdownLinkTextDelimiter`, `markdownUrlDelimiter` |

## Global match color

The `match` color role in `colors.lua` uses the primary red `#f97583`.
`defaults.get_ui(colors)` applies it to the global `list.highlightForeground`
UI key, shared by the existing picker/completion mappings. `PmenuMatch` and
`PmenuMatchSel` use the same role for native completion menus, including the
suggestions shown while typing `/`. These highlights change only the foreground
and preserve the menu background. Editor matches use separate `Search`,
`IncSearch` and `CurSearch` groups, retaining the original active red/orange
accents, editor background and `inverse` option.
No plugin-specific setup or highlight override is needed. The bundled VS Code
source remains unchanged; `vscode.audit(defaults.get(colors), defaults.get_ui(colors))`
records the global UI color choice alongside the original source value.

## Native autocomplete surface

`palette.cmdline_bg` defaults to `#161616` and supplies `Pmenu` and
`PmenuSbar`, used by native command-line completion (including `mini.cmdline`).
Blink's menu and border have independent definitions using `panel_bg` (`#121212`),
so native completion background changes do not recolor the other menus. Match
foregrounds and selected-item highlights retain their existing colors. The same
`Pmenu` surface is also used by native insert-mode completion; Blink uses its
own groups.

## Selected menu rows

The original `list.activeSelectionForeground` value (`#F5F5F5`) recolors the
selected item through `PmenuSel`, `BlinkCmpMenuSelection` and
`SnacksPickerListCursorLine`. The fork sets this global UI key to fully
transparent (`#00000000`), so the compiler emits no selection foreground.
Their base definitions also omit foregrounds. Selection backgrounds still use
`list.activeSelectionBackground` (`#212121`); native completion keeps its bold
selection style.

Matched characters keep `list.highlightForeground` (`#f97583`) via
`SnacksPickerMatch`, `BlinkCmpLabelMatch`, `PmenuMatch` and `PmenuMatchSel`.
The original VS Code source stays unchanged, and the audit records the global
UI adaptation. Editor `Search`, `IncSearch`, `CurSearch` and `Visual` groups are
independent of these menu selection roles.
