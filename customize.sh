SKIPUNZIP=0

ui_print "*****************************************"
ui_print "*   GKI Hotspot Shield & TTL/DPI Fixer  *"
ui_print "*               v3.0 Ultra              *"
ui_print "*             by alperozd               *"
ui_print "*****************************************"

ui_print "- Setting up permissions..."
set_perm "$MODPATH/nfqttl" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/system/bin/ttlshield" 0 0 0755

ui_print "- Initializing service..."
killall -9 nfqttl ttlfixer 2>/dev/null
nohup sh "$MODPATH/service.sh" </dev/null >/dev/null 2>&1 &

ui_print "- Installation completed successfully!"
