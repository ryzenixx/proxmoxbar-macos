import os.path

application = defines.get("app", "ProxmoxBar.app")
appname = os.path.basename(application)

format = "UDZO"
files = [application]
symlinks = {"Applications": "/Applications"}
hide_extension = [appname]

window_rect = ((200, 120), (600, 360))
default_view = "icon-view"
icon_size = 128
text_size = 13
icon_locations = {
    appname: (150, 160),
    "Applications": (450, 160),
}
