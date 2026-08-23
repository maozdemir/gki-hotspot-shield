#!/system/bin/sh
MODDIR=${0%/*}

# 1. Android System & DUN Parameters Reset
resetprop tether_dun_required 0
resetprop net.tethering.noprovisioning true
resetprop tether_entitlement_check_state 0
settings put global tether_dun_required 0 2>/dev/null
settings put global tether_entitlement_check_state 0 2>/dev/null

# 2. Kernel Default TTL & Hop Limit
echo 64 > /proc/sys/net/ipv4/ip_default_ttl
echo 64 > /proc/sys/net/ipv6/conf/all/hop_limit

# 3. Anti-Bufferbloat Sysctls
sysctl -w net.core.default_qdisc=fq_codel 2>/dev/null
sysctl -w net.ipv4.tcp_slow_start_after_idle=0 2>/dev/null
sysctl -w net.ipv4.tcp_notsent_lowat=16384 2>/dev/null
sysctl -w net.ipv4.tcp_ecn=1 2>/dev/null
sysctl -w net.ipv4.tcp_autocorking=0 2>/dev/null
sysctl -w net.core.netdev_max_backlog=4096 2>/dev/null
sysctl -w net.ipv4.tcp_fastopen=3 2>/dev/null

until [ "$(getprop sys.boot_completed)" = 1 ]; do
    sleep 1
done

# Repeat properties after boot completion
resetprop tether_dun_required 0
resetprop net.tethering.noprovisioning true
resetprop tether_entitlement_check_state 0
settings put global tether_dun_required 0 2>/dev/null
settings put global tether_entitlement_check_state 0 2>/dev/null

# 4. Start Go TTL, DPI & DoH Daemon
killall -9 nfqttl ttlfixer 2>/dev/null
$MODDIR/nfqttl > /dev/null 2>&1 &

# 5. iptables NFQUEUE Rules
iptables -t mangle -N nfqttli 2>/dev/null
iptables -t mangle -F nfqttli
iptables -t mangle -A nfqttli -j NFQUEUE --queue-num 6464

iptables -t mangle -N nfqttlo 2>/dev/null
iptables -t mangle -F nfqttlo
iptables -t mangle -A nfqttlo -j NFQUEUE --queue-num 6464

iptables -t mangle -C PREROUTING -j nfqttli 2>/dev/null || iptables -t mangle -A PREROUTING -j nfqttli
iptables -t mangle -C OUTPUT -j nfqttlo 2>/dev/null || iptables -t mangle -A OUTPUT -j nfqttlo
iptables -t mangle -C POSTROUTING -j nfqttlo 2>/dev/null || iptables -t mangle -A POSTROUTING -j nfqttlo

# 6. TCP MSS Clamping to PMTU
iptables -t mangle -C FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# 7. Transparent DNS-over-HTTPS (DoH) Redirection (Port 53 -> 5353)
iptables -t nat -C PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null || iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5353
iptables -t nat -C PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null || iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 5353

# 8. Dynamic Hotspot-Aware QoS & Power Saver Guard
(
    last_state="unknown"
    while true; do
        if iptables -t nat -S tetherctrl_nat_POSTROUTING 2>/dev/null | grep -q "MASQUERADE"; then
            current_state="active"
            if [ "$last_state" != "active" ]; then
                last_state="active"
            fi

            for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -E 'wlan|rmnet|ap|rndis'); do
                clean_iface=$(echo "$iface" | cut -d'@' -f1)
                tc qdisc replace dev "$clean_iface" root fq_codel 2>/dev/null
                iw dev "$clean_iface" set power_save off 2>/dev/null
            done
        else
            current_state="idle"
            if [ "$last_state" = "active" ]; then
                for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -E 'wlan|ap'); do
                    clean_iface=$(echo "$iface" | cut -d'@' -f1)
                    iw dev "$clean_iface" set power_save on 2>/dev/null
                done
                last_state="idle"
            fi
        fi
        sleep 5
    done
) > /dev/null 2>&1 &
