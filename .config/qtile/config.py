from libqtile.manager import Key, Screen, Group
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

groups = [
    Group("1"),
    Group("2"),
    Group("3"),
    Group("4"),
    Group("5"),
    Group("6"),
    Group("q"),
    Group("w"),
    Group("e"),
    Group("r"),
    Group("t"),
    Group("7"),
    Group("8"),
    Group("9"),
    Group("0"),
]
for i in groups:
    keys.append(
        Key([MOD], i.name, lazy.group[i.name].toscreen())
    )
    keys.append(
        Key([MOD, "shift"], i.name, lazy.window.togroup(i.name))
    )

layouts = [
    layout.Max(),
    layout.Stack(stacks=2)
]

screens = [
    Screen(
        top = bar.Bar(
                    [
                        widget.GroupBox(),
                        widget.WindowName(),
                        widget.TextBox("left", "default config"),
                        widget.Systray(),
                        widget.Clock('%Y-%m-%d %a %I:%M %p'),
                    ],
                    30,
                ),
    ),
    Screen(
        top = bar.Bar(
                    [
                        widget.GroupBox(),
                        widget.WindowName(),
                        widget.TextBox("right", "default config"),
                        widget.Systray(),
                        widget.Clock('%Y-%m-%d %a %I:%M %p'),
                    ],
                    30,
                ),
    ),
]

main = None
follow_mouse_focus = True
cursor_warp = False
floating_layout = layout.Floating()
mouse = ()

