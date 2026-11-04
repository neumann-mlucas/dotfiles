------------------
---- MONITORS ----
------------------

-- Stable identifiers. `desc:` matches EDID → survives connector swap (USB-C dock, HDMI vs DP).
-- `auto-left` / `auto-right` avoid hardcoded x offsets when resolutions change.
local LAPTOP = "desc:BOE 0x0791"
local ULTRAWIDE = "desc:LG Electronics LG HDR WFHD 0x0002C004"

-- Laptop panel — always primary/anchor
hl.monitor({ output = LAPTOP, mode = "preferred", position = "auto", scale = 1 })
-- Main ultrawide monitor
hl.monitor({ output = ULTRAWIDE, mode = "preferred", position = "auto-left", scale = 1 })
-- Catch-all: anything else plugged in gets sane defaults
hl.monitor({ output = "", mode = "preferred", position = "auto-right", scale = 1 })

-- Workspace assignment
hl.workspace_rule({ workspace = "1", monitor = LAPTOP, default = true })
hl.workspace_rule({ workspace = "2", monitor = LAPTOP })
hl.workspace_rule({ workspace = "3", monitor = LAPTOP })
hl.workspace_rule({ workspace = "4", monitor = LAPTOP })
hl.workspace_rule({ workspace = "5", monitor = LAPTOP })
hl.workspace_rule({ workspace = "6", monitor = LAPTOP })
hl.workspace_rule({ workspace = "7", monitor = ULTRAWIDE, layout = "scrolling" })
hl.workspace_rule({ workspace = "8", monitor = ULTRAWIDE, layout = "scrolling" })
hl.workspace_rule({ workspace = "9", monitor = ULTRAWIDE, layout = "scrolling" })
hl.workspace_rule({ workspace = "10", monitor = ULTRAWIDE, layout = "scrolling" })

---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "ghostty"
local menu = "wofi --show drun"

local browser = "firefox"
local clipMenu = "cliphist list | wofi --dmenu | cliphist decode | wl-copy"
local screenshot = 'grim -g "$(slurp)"'
local speedRead = os.getenv("HOME") .. "/.go/bin/GoSpeedRead"
local surfrawMenu = os.getenv("HOME") .. "/.local/bin/menu-surfraw"
local wsSwitcher = os.getenv("HOME") .. "/.local/bin/switch-workspaces"
local winSwitcher = os.getenv("HOME") .. "/.local/bin/switch-windows"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
  -- Export Wayland session vars into user dbus + systemd so portals/services see them
  hl.exec_cmd(
    "dbus-update-activation-environment --systemd "
      .. "WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP DISPLAY LANG LC_ALL"
  )
  -- NetworkManager tray icon (Wi-Fi/VPN menu)
  hl.exec_cmd("nm-applet")
  -- Notification daemon (desktop notifications)
  hl.exec_cmd("mako")
  -- Status bar; sleep 2s to let tray/systray clients register first
  hl.exec_cmd("sh -c 'sleep 2 && waybar'")
  -- Wallpaper daemon (reads ~/.config/hypr/hyprpaper.conf)
  hl.exec_cmd("hyprpaper")
  -- Time-of-day wallpaper rotation (waits for hyprpaper, enumerates monitors)
  hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/change-wallpaper")
  -- Day/night blue-light profiles in hyprsunset.conf
  hl.exec_cmd("hyprsunset")
  -- Clipboard history watcher (feeds SUPER+Y menu)
  hl.exec_cmd("wl-paste --watch cliphist store")
  -- ActivityWatch tray (time tracker)
  hl.exec_cmd("aw-qt")
end)

hl.on("monitor.added", function(monitor)
  hl.exec_cmd("notify-send 'Monitor connected: " .. monitor.name .. "'")
end)

-- Dump session state on shutdown
hl.on("hyprland.shutdown", function()
  local dir = os.getenv("HOME") .. "/.local/state/hyprland"
  hl.exec_cmd("mkdir -p " .. dir)
  local ts = os.date("%Y%m%d-%H%M%S")
  hl.exec_cmd("hyprctl -j clients    > " .. dir .. "/clients-" .. ts .. ".json")
  hl.exec_cmd("hyprctl -j workspaces > " .. dir .. "/workspaces-" .. ts .. ".json")
  hl.exec_cmd("hyprctl -j monitors   > " .. dir .. "/monitors-" .. ts .. ".json")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("LANG", "C.UTF-8")
hl.env("LC_ALL", "C.UTF-8")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 1,
    col = {
      -- Kanagawa Wave: crystalBlue → springBlue gradient, sumiInk4 inactive
      active_border = { colors = { "rgba(7E9CD8ee)", "rgba(7FB4CAee)" }, angle = 45 },
      inactive_border = "rgba(54546Daa)",
    },
    resize_on_border = true,
    allow_tearing = false,
    layout = "dwindle",
  },

  decoration = {
    rounding = 10,
    rounding_power = 4,
    active_opacity = 1.0,
    inactive_opacity = 0.6,
    shadow = {
      enabled = true,
      range = 10,
      render_power = 3,
      color = 0xee16161d,
    },
    blur = {
      enabled = true,
      size = 8,
      passes = 1,
      vibrancy = 0.1696,
    },
  },

  animations = {
    enabled = true,
  },

  dwindle = {
    preserve_split = true,
  },

  master = {
    new_status = "master",
  },

  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
  },

  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "compose:ralt",
    kb_rules = "",
    follow_mouse = 0,
    sensitivity = 0,
    repeat_rate = 120,
    repeat_delay = 180,
    touchpad = {
      natural_scroll = false,
    },
  },
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(surfrawMenu))

hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd(clipMenu))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(screenshot))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(speedRead))

hl.bind(mainMod .. " + S", hl.dsp.window.swap({ next = true }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.pseudo())

-- Move focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Switch-windows / switch-workspaces menus
hl.bind(mainMod .. " + grave", hl.dsp.exec_cmd(winSwitcher))
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.exec_cmd(wsSwitcher))

-- Workspaces 1-10
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "previous" }))

-- Mouse move/resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume / brightness
hl.bind(
  "XF86AudioRaiseVolume",
  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioLowerVolume",
  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioMute",
  hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioMicMute",
  hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
  { locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

-- playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

--------------------------------
---- WINDOW RULES            ----
--------------------------------

hl.window_rule({
  name = "gospeedread-float",
  match = { class = "GoSpeedRead" },
  float = true,
  center = true,
  size = "1200 400",
})
