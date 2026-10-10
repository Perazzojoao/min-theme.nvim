-- Min Dark palette for min-theme.nvim

---@class ThemePalette
local palette = {
  -- Surfaces (dark backgrounds)
  surface_dark_0_hard = "#141414",
  surface_dark_0 = "#121212",
  surface_dark_0_soft = "#242424",
  surface_dark_1 = "#2A2A2A",
  surface_dark_2 = "#303030",
  surface_dark_3 = "#383838",
  surface_dark_4 = "#444444",

  -- Separate semantic surfaces; bg1 remains available for secondary UI.
  panel_bg = "#121212",
  cursorline = "#181818",
  selection = "#2a2a2a",
  border = "#383838",
  link = "#368cfc",

  -- Foreground/text surfaces
  surface_light_0 = "#C1C1C1",
  surface_light_1 = "#cfcfcf",
  surface_light_2 = "#bbbbbb",
  surface_light_3 = "#888888",
  surface_light_4 = "#727272",

  -- Primary accent family (red/pink → orange)
  primary = "#f97583",
  primary_active = "#FF7A84",
  primary_soft = "#ffab70",
  primary_muted = "#FF9800",
  primary_dark = "#5c2225",

  -- Secondary accent family (purple → blue → blue-gray)
  secondary = "#b392f0",
  secondary_active = "#79b8ff",
  secondary_soft = "#9db1c5",

  -- Diff surfaces
  diff_primary_dark_hard = "#3d1517",
  diff_primary_dark = "#451a1c",
  diff_primary_dark_soft = "#4d1f21",
  diff_secondary_dark_hard = "#1a2e1a",
  diff_secondary_dark = "#1f3320",
  diff_secondary_dark_soft = "#243826",
  diff_tertiary_dark_hard = "#1d2425",
  diff_tertiary_dark = "#222b2c",
  diff_tertiary_dark_soft = "#273233",

  -- Utility roles
  warning = "#cd9731",
  info = "#79b8ff",
  success = "#9bc774",
  git_added = "#8fc07a",
  git_modified = "#d7ab73",
  git_deleted = "#FF7A84",
  neutral = "#6b737c",
}

return palette
