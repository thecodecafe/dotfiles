local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font('CommitMono Nerd Font Mono')
config.font_size = 12

config.window_background_opacity = 0.9
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

local colors = {
  background = '#000000',
  foreground = '#E8EAED',
  cursor = '#FE8010',
  selection = '#FE8019',
  active_tab = '#1A1A1A',
  inactive_tab = '#000000',
  inactive_tab_hover = '#101010',
  inactive_tab_foreground = '#A0A0A0',
}

config.colors = {
  background = colors.background,
  foreground = colors.foreground,
  cursor_bg = colors.cursor,
  cursor_border = colors.cursor,
  cursor_fg = colors.background,
  selection_bg = colors.selection,
  tab_bar = {
    background = colors.background,
    active_tab = {
      bg_color = colors.active_tab,
      fg_color = colors.foreground,
    },
    inactive_tab = {
      bg_color = colors.inactive_tab,
      fg_color = colors.inactive_tab_foreground,
    },
    inactive_tab_hover = {
      bg_color = colors.inactive_tab_hover,
      fg_color = colors.foreground,
    },
    new_tab = {
      bg_color = colors.background,
      fg_color = colors.inactive_tab_foreground,
    },
    new_tab_hover = {
      bg_color = colors.inactive_tab_hover,
      fg_color = colors.foreground,
    },
  },
}

wezterm.on('format-tab-title', function(tab, _, _, _, hover, max_width)
  local title = tab.tab_title
  if not title or title == '' then
    title = tab.active_pane.title
  end

  if max_width and max_width > 2 then
    title = wezterm.truncate_right(title, max_width - 2)
  end

  local background = colors.inactive_tab
  local foreground = colors.inactive_tab_foreground
  if tab.is_active then
    background = colors.active_tab
    foreground = colors.foreground
  elseif hover then
    background = colors.inactive_tab_hover
    foreground = colors.foreground
  end

  return {
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = ' ' .. title .. ' ' },
  }
end)

return config
