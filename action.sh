#!/system/bin/sh

echo "========================================="
echo "   🛡️ GKI Hotspot Shield & TTL Fixer    "
echo "========================================="
echo ""

# Ensure daemon is running
if ! ps -A | grep -q nfqttl; then
    echo "[*] Starting daemon..."
    killall -9 nfqttl ttlfixer 2>/dev/null
    nohup /data/adb/modules/nfqttl/nfqttl </dev/null >/dev/null 2>&1 &
    sleep 1
fi

# Fetch and display current live stats
echo "[+] Status & Live Statistics:"
if [ -f /data/local/tmp/ttlfixer_stats.json ]; then
    cat /data/local/tmp/ttlfixer_stats.json
else
    echo "    Running on 127.0.0.1:64640"
fi
echo ""

# Detect default browser and launch WebUI
URL="http://127.0.0.1:64640"
echo "[*] Launching WebUI Dashboard at $URL..."

BROWSER=$(pm resolve-activity -a android.intent.action.VIEW -d "$URL" 2>/dev/null | grep packageName | head -n1 | cut -d'=' -f2)

if [ -n "$BROWSER" ]; then
    am start -a android.intent.action.VIEW -d "$URL" -p "$BROWSER" --user 0 -f 0x10000000 >/dev/null 2>&1
fi
am start -a android.intent.action.VIEW -d "$URL" --user 0 -f 0x10000000 >/dev/null 2>&1

echo ""
echo "✅ Dashboard launched!"
echo "If browser did not pop up, open your browser and navigate to:"
echo "👉 http://127.0.0.1:64640"
echo "========================================="
sleep 2
