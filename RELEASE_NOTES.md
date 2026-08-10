## 3.0.2

**A tighter dashboard.** The header was pushing the machine list halfway down the panel. Nodes, load, and the Machines/Storage controls now sit closer together with fewer separators, so your machines start near the top.

## 3.0.1

**The widget now shows up.** In 3.0.0 the widget extension shipped without its full entitlements, so macOS refused to register it and it never appeared in the widget gallery. That is fixed. Add it from the desktop's Edit Widgets, then pick a server.

## 3.0.0

Welcome to ProxmoxBar 3.0 

ProxmoxBar has been rebuilt from the ground up, with support for macOS 27 Golden Gate.

**You will need to add your server again.** The way ProxmoxBar stores your configuration was rewritten along with the rest of the app. Carrying the old format forward would have meant carrying its quirks, so 3.0 starts clean. Your address and an API token, and you are back where you were in under a minute. Sorry for the small detour.

**Requires macOS 15 or later.** If you are still on Sonoma, this update will not reach you and 2.0.6 keeps working exactly as before.

**A reading in the menu bar.** The icon can now show your running machine count or your cluster CPU, so you can check on things without opening anything.

**Widgets on your desktop.** Add a small or medium widget for any of your servers, and see nodes online, machines running and load at a glance without opening the app.

**Notifications across every server.** Get a banner when a machine starts or stops, or a node drops offline and comes back, on all your servers rather than only the one on screen, and never for the changes you make yourself.

**Steadier, and honest about it.** Everything you relied on is still here. When the cluster goes quiet, ProxmoxBar now says so instead of leaving stale numbers on screen.

Thank you for using ProxmoxBar, and please report anything that breaks.
