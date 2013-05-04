from libqtile.manager import Drag, Group, Key, Screen
from libqtile.command import lazy
from libqtile import layout, bar, widget

ALT = "mod1"
MOD = "mod4"
CTRL = "control"

keys = [
    # Multi-monitor / Away Mode
    Key(
        ["mod1", "control"], "m",
        lazy.spawn("xrandr --output VGA1 --mode 1920x1200 --left-of LVDS1 --output LVDS1 --mode 1600x900")
    ),
    Key(
        ["mod1", "control", "shift"], "m",
        lazy.spawn("xrandr --output VGA1 --off")
    ),

    Key(
        ["mod1"], "Tab",
        lazy.layout.down()
    ),
    Key(
        ["mod1", "shift"], "Tab",
        lazy.layout.up()
    ),
    Key(
        [MOD], "comma",
        lazy.layout.shuffle_down()
    ),
    Key(
        [MOD], "period",
        lazy.layout.shuffle_up()
    ),
    Key(
        [MOD], "space",
        lazy.layout.next()
    ),
    Key(
        [MOD, "shift"], "space",
        lazy.layout.rotate()
    ),
    Key(
        [MOD, "shift"], "Return",
        lazy.layout.toggle_split()
    ),
    Key(
        [], "XF86AudioLowerVolume",
        lazy.spawn("amixer -q set Master 2- unmute")
    ),
    Key(
        [], "XF86AudioRaiseVolume",
        lazy.spawn("amixer -q set Master 2+ unmute")
    ),
    Key(
        [], "XF86AudioMute",
        lazy.spawn("amixer -q set Master toggle")
    ),
    Key([MOD], "h",      lazy.to_screen(1)),
    Key([MOD], "l",      lazy.to_screen(0)),
    Key([MOD], "Return", lazy.spawn("gnome-terminal")),
    Key([MOD], "n",      lazy.nextlayout()),
    Key([MOD], "b",      lazy.prevlayout()),
    Key([MOD], "k",      lazy.window.kill()),

    Key([CTRL, ALT], "r", lazy.restart()),
]

groups = [Group(c) for c in "123456qwert7890"]
for i in groups:
    keys.append(
        Key([MOD], i.name, lazy.group[i.name].toscreen())
    )
    keys.append(
        Key([MOD, "shift"], i.name, lazy.window.togroup(i.name))
    )

layouts = [
    layout.Max(),
    layout.Stack(stacks=2, border_width=1)
]

screens = [
    Screen(
        top = bar.Bar(
                    [
                        widget.GroupBox(urgent_alert_method='text', fontsize=8),
                        widget.Sep(),
                        widget.Prompt(),
                        widget.WindowName(),
                        widget.Sep(),
                        widget.TextBox("right", u'\u266B'),
                        widget.Volume(),
                        widget.TextBox("right", "Bat:"),
                        widget.Battery(
                            energy_now_file='charge_now',
                            energy_full_file='charge_full',
                            power_now_file='current_now',
                        ),
                        widget.CPUGraph(width=42, line_width=2, graph_color='0066FF', fill_color='001188'),
                        widget.MemoryGraph(width=42, line_width=2, graph_color='22FF44', fill_color='11AA11'),
                        widget.NetGraph(width=42, line_width=2, graph_color='FF9F20', fill_color='C06010'),
                        widget.SwapGraph(width=20, line_width=2, graph_color='FF2020', fill_color='C01010'),
                        widget.HDDGraph(width=20, line_width=2, graph_color='FF2020', fill_color='C01010'),
                        widget.Sep(),
                        widget.Systray(),
                        widget.Sep(),
                        widget.Clock('%Y-%m-%d %a %I:%M %p'),
                    ],
                    20,
                ),
    ),
    Screen(
        top = bar.Bar(
                    [
                        widget.GroupBox(urgent_alert_method='text', fontsize=8),
                        widget.Sep(),
                        widget.Prompt(),
                        widget.WindowName(),
                        widget.Sep(),
                        widget.TextBox("right", u'\u266B'),
                        widget.Volume(),
                        widget.TextBox("right", "Bat:"),
                        widget.Battery(
                            energy_now_file='charge_now',
                            energy_full_file='charge_full',
                            power_now_file='current_now',
                        ),
                        widget.CPUGraph(width=42, line_width=2, graph_color='0066FF', fill_color='001188'),
                        widget.MemoryGraph(width=42, line_width=2, graph_color='22FF44', fill_color='11AA11'),
                        widget.NetGraph(width=42, line_width=2, graph_color='FF9F20', fill_color='C06010'),
                        widget.SwapGraph(width=20, line_width=2, graph_color='FF2020', fill_color='C01010'),
                        widget.HDDGraph(width=20, line_width=2, graph_color='FF2020', fill_color='C01010'),
                        widget.Sep(),
                        widget.Systray(),
                        widget.Sep(),
                        widget.Clock('%Y-%m-%d %a %I:%M %p'),
                    ],
                    20,
                ),
    ),
]

main = None
follow_mouse_focus = True
cursor_warp = False
floating_layout = layout.Floating()
mouse = [
    Drag([MOD], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([MOD], "Button3", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
]

# Automatically float these types. This overrides the default behavior (which
# is to also float utility types), but the default behavior breaks our fancy
# gimp slice layout specified later on.
floating_layout = layout.Floating(auto_float_types=[
  "notification",
  "toolbar",
  "splash",
  "dialog",
  "utility",
])
