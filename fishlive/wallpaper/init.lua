--[[

     Fishlive Lua Library
     Wallpaper Extension for Awesome WM

     Licensed under GNU General Public License v2
      * (c) 2022, A.Fischer
--]]

local gears = require("gears")
local helpers = require("fishlive.helpers")

-- fishlive wallpaper submodule
-- fishlive.wallpaper
local wallpaper = { _NAME = "fishlive.wallpaper" }

-- User Wallpaper Changer
function wallpaper.createUserWallpaper(t)
  local wppath_user = t.wppath_user
  local wp_user = helpers.scandir(wppath_user)
  local wp_user_idx = 0
  t.wp_user = wp_user

  return function(direction, scr)
    local maxIdx = #wp_user
    wp_user_idx = wp_user_idx + direction
    if wp_user_idx < 1 then wp_user_idx = maxIdx end
    if wp_user_idx > maxIdx then wp_user_idx = 1 end

    local wp = wp_user[wp_user_idx]

    if not scr then scr = mouse.screen end

    local tag = scr.selected_tag
    if tag.selected then
      t.wallpaper_user = wppath_user .. wp
      t.wallpaper_user_tag = tag
      awesome.emit_signal("wallpaper::change", t.wallpaper_user)
      gears.wallpaper.maximized(t.wallpaper_user, scr, false)
    end
  end
end

-- Tag Wallpaper Changer
function wallpaper.registerTagWallpaper(t)
  local scr = t.screen
  local wp_selected = t.wp_selected
  local wp_portrait = t.wp_portrait
  local wp_random = t.wp_random
  local wppath = t.wppath
  local wp_user_params = t.wp_user_params
  local wp_colorscheme_params = t.wp_colorscheme_params
  local change_wallpaper_colorscheme = t.change_wallpaper_colorscheme

  -- Detect if the screen is in portrait mode
  local is_portrait = scr.geometry.width < scr.geometry.height
  -- Set actual wallpaper for first tag and screen
  local imgidx = scr.tags[1].bidx and scr.tags[1].bidx or 1
  local wp = is_portrait and wp_portrait[imgidx] or wp_selected[imgidx]
  if wp == "random" then wp = wp_random[1] end
  awesome.emit_signal("wallpaper::change", wppath .. wp)
  gears.wallpaper.maximized(wppath .. wp, scr, false)

  -- Go over each tab
  for t = 1, #scr.tags do
    local tag = scr.tags[t]
    --todo sharedtags - active tag is moved to another screen - ensure notification
    tag:connect_signal("property::selected", function(tag)
      -- And if selected
      if not tag.selected then return end
      local imgidx = tag.bidx and tag.bidx or t
      -- Set random wallpaper
      if wp_user_params.wallpaper_user_tag == tag then
        wp = wp_user_params.wallpaper_user
      elseif wp_colorscheme_params.wallpaper_user_tag == tag then
        wp = wp_colorscheme_params.wallpaper_user
      elseif wp_selected[imgidx] == "random" then
        local position = math.random(1, #wp_random)
        wp = wppath .. wp_random[position]
      elseif wp_selected[imgidx] == "colorscheme" then
        if not wp_colorscheme_params.wallpaper_user then
          change_wallpaper_colorscheme(1, tag.screen)
        end
        wp = wp_colorscheme_params.wallpaper_user
      else
        wp = wppath .. (is_portrait and wp_portrait[imgidx] or wp_selected[imgidx])
      end
      awesome.emit_signal("wallpaper::change", wp)
      gears.wallpaper.maximized(wp, tag.screen, false)
    end)
  end
end

return wallpaper
