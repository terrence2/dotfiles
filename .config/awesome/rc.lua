-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/default/theme.lua")

-- This is used later as the default terminal and editor to run.
hostname = awful.util.pread("hostname"):gsub("\n", "")

-- Usually, Mod4 is the key with a logo between Control and Alt.
MODKEY = "Mod4"
TERMINAL = "gnome-terminal"
if string.find(hostname, "capuchin") == 1 then
    MODKEY = "Mod1"
    TERMINAL = "urxvt"
end

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.max,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile
}
local fullscreenLayouts =
{
    awful.layout.suit.max,
    awful.layout.suit.max.fullscren
}
local allLayouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.floating,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Wallpaper
--if beautiful.wallpaper then
--    for s = 1, screen.count() do
--        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
--    end
--end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tagSet = {1, 2, 3, 4, 5, 6, 7, 8, 9, 0}
    tags[s] = awful.tag(tagSet, s, layouts[1])
end
-- }}}

-- {{{ Menu
mymainmenu = awful.menu({ items = { { "open terminal", TERMINAL },
                                    { "restart", awesome.restart },
                                  }
                        })
-- }}}

-- Menubar configuration
menubar.utils.terminal = TERMINAL -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock()

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ MODKEY }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ MODKEY }, 3, awful.client.toggletag)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Create an ACPI widget
    batterywidget = wibox.widget.textbox()
    batterywidgettimer = timer({ timeout = 30 })
    batterywidgettimer:connect_signal("timeout",
      function()
        fh = assert(io.popen("acpi | cut -d, -f 2,3 - | sed 's/, discharging at zero rate - will never fully discharge.//'", "r"))
        res = fh:read("*l")
        if res then
            batterywidget:set_text(" | 🔋" .. res .. " | ")
        end
        fh:close()
      end
    )
    batterywidgettimer:start()
    batterywidgettimer:emit_signal("timeout")

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    --left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(batterywidget)
    right_layout:add(mytextclock)
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ MODKEY,           }, "Escape", awful.tag.history.restore),

    awful.key({ "Control",        }, ".",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ "Control",        }, ",",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ MODKEY,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ MODKEY            }, "l", function () awful.tag.incmwfact( 0.05) end),
    awful.key({ MODKEY            }, "h", function () awful.tag.incmwfact(-0.05) end),
    awful.key({ MODKEY, "Shift"   }, "l", function () awful.client.incwfact(-0.05) end),
    awful.key({ MODKEY, "Shift"   }, "h", function () awful.client.incwfact( 0.05) end),
    awful.key({ "Control", "Shift"}, ".", function () awful.client.swap.byidx(  1)    end),
    awful.key({ "Control", "Shift"}, ",", function () awful.client.swap.byidx( -1)    end),
    awful.key({ MODKEY,           }, "u", awful.client.urgent.jumpto),
    awful.key({ MODKEY,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),
    awful.key({ "Mod1",           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ MODKEY,           }, "Return", function () awful.util.spawn(TERMINAL) end),
    awful.key({ MODKEY, "Control" }, "r", awesome.restart),
    awful.key({ MODKEY, "Shift"   }, "q", awesome.quit),

    awful.key({ MODKEY,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ MODKEY, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),
    awful.key({ MODKEY, "Control",        }, "space", function () awful.layout.inc(allLayouts, 1) end),
    awful.key({ MODKEY, "Control", "Shift"}, "space", function () awful.layout.inc(allLayouts, -1) end),
    awful.key({ MODKEY,           }, "F4", function () awful.layout.inc(fullscreenLayouts, 1) end),

    awful.key({ MODKEY, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ MODKEY },            "r",     function () mypromptbox[mouse.screen]:run() end),
    awful.key({ MODKEY, "Shfit" },   "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ MODKEY }, "p", function() menubar.show() end)
)

-- System Control
if string.find(hostname, "capuchin") == 1 then
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ MODKEY }, "F6",
            function (c)
                fh = assert(io.popen("brightness -", "r"))
                fh:read("*all")
                fh:close()
            end),
        awful.key({ MODKEY }, "F7",
            function (c)
                fh = assert(io.popen("brightness +", "r"))
                fh:read("*all")
                fh:close()
            end),
        -- Speaker Controls
        awful.key({ MODKEY }, "F8",
            function (c)
                fh = assert(io.popen("daisyctl --speaker=toggle", "r"))
                fh:read("*all")
                fh:close()
            end),
        awful.key({ MODKEY }, "F9",
            function (c)
                fh = assert(io.popen("daisyctl --speaker=-", "r"))
                fh:read("*all")
                fh:close()
            end),
        awful.key({ MODKEY }, "F10",
            function (c)
                fh = assert(io.popen("daisyctl --speaker=+", "r"))
                fh:read("*all")
                fh:close()
            end),
        -- Headphone Controls
        awful.key({ MODKEY, "Control" }, "F8",
            function (c)
                fh = assert(io.popen("daisyctl --headphones=toggle", "r"))
                fh:read("*all")
                fh:close()
            end),
        awful.key({ MODKEY, "Control" }, "F9",
            function (c)
                fh = assert(io.popen("daisyctl --headphones=-", "r"))
                fh:read("*all")
                fh:close()
            end),
        awful.key({ MODKEY, "Control" }, "F10",
            function (c)
                fh = assert(io.popen("daisyctl --headphones=+", "r"))
                fh:read("*all")
                fh:close()
            end),
        -- Power controls
        awful.key({ MODKEY }, "XF86PowerOff",
            function (c)
                fh = assert(io.popen("sleep 5 && systemctl suspend"))
                fh:read("*all")
                fh:close()
            end),
        awful.key({ MODKEY, "Control", "Shift" }, "XF86PowerOff",
            function (c)
                fh = assert(io.popen("sleep 5 && systemctl poweroff"))
                fh:read("*all")
                fh:close()
            end)
    )
end

clientkeys = awful.util.table.join(
    awful.key({ MODKEY,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ MODKEY, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ MODKEY, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ MODKEY, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ MODKEY,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ MODKEY,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ MODKEY,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ MODKEY,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ MODKEY }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ MODKEY, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ MODKEY, "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.movetotag(tag)
                     end
                  end),
        awful.key({ MODKEY, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.toggletag(tag)
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ MODKEY }, 1, awful.mouse.client.move),
    awful.button({ MODKEY }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- Run network manager.
os.execute("nm-applet &")

