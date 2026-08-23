# GKI Hotspot Shield & TTL/DPI Fixer

[![Release](https://img.shields.io/github/v/release/maozdemir/gki-hotspot-shield?style=flat-square)](https://github.com/maozdemir/gki-hotspot-shield/releases)
[![License](https://img.shields.io/badge/License-GPL%203.0-blue.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20GKI%20(12%2B)-green.svg?style=flat-square)](https://source.android.com/docs/core/architecture/kernel/generic-kernel-image)

An all-in-one network engine and Magisk/KernelSU/APatch module designed for modern Android devices running Generic Kernel Image (GKI) kernels (Android 12, 13, 14, 15, 16).

---

## 🌟 Why This Project?

On modern Android GKI kernels (kernel 5.4, 5.10, 5.15, 6.1, 6.6, 6.12+), Google removed the traditional netfilter target CONFIG_IP_NF_TARGET_TTL. As a result, classic iptables -t mangle -j TTL --ttl-set 64 rules fail with:
`	ext
Warning: Extension TTL revision 0 not supported, missing kernel module?
iptables: No chain/target/match by that name.
`

**GKI Hotspot Shield** solves this natively without needing custom kernel recompilations by leveraging NFQUEUE (Netfilter Netlink Queue) and a high-performance, lightweight pure Go daemon.

---

## 🚀 Key Features

1. **⚡ Real-Time TTL & Hop Limit Normalization (TTL=64)**
   - Intercepts all incoming hotspot traffic and outgoing WAN packets.
   - Normalizes IPv4 TTL and IPv6 Hop Limit to 64 in microseconds with zero perceptible latency.
   - Automatically recalculates IPv4 header checksums.

2. **🛡️ GoodbyeDPI / Zapret TLS ClientHello TCP Segmentation**
   - Detects initial HTTPS TLS ClientHello (SNI) and HTTP request packets.
   - Splits the TCP payload into segments at byte-level to evade Deep Packet Inspection (DPI) and OS fingerprinting.
   - Functions as a network-wide DPI bypass for all devices connected to the phone's hotspot (Windows, Mac, iOS, Android, Consoles).

3. **🎮 Anti-Bufferbloat QoS (q_codel)**
   - Applies Fair Queueing with Controlled Delay (q_codel) on active network interfaces.
   - Isolates ping/gaming packets from large video streaming and download flows to eliminate ping spikes.

4. **🔋 Smart Hotspot-Aware Wi-Fi Battery Guard**
   - Automatically disables Wi-Fi power saving (power_save off) **only** while hotspot is active (preventing latency jitter when screen turns off).
   - Instantly restores normal Wi-Fi power saving (power_save on) when hotspot is turned off to preserve battery life.

5. **📱 Carrier DUN & Entitlement Bypass**
   - Automatically cleans Android properties: 	ether_dun_required, 
et.tethering.noprovisioning, and 	ether_entitlement_check_state.
   - Sets kernel default TTLs: 
et.ipv4.ip_default_ttl=64 and 
et.ipv6.conf.all.hop_limit=64.

6. **⚙️ Simple Configuration (config.conf)**
   - Configurable settings in /data/adb/modules/nfqttl/config.conf:
     `ini
     TARGET_TTL=64
     TCP_SPLIT=1
     SPLIT_POS=2
     BUFFERBLOAT_QOS=1
     WIFI_POWER_SAVE_LOCK=1
     TCP_LOW_LATENCY=1
     `

7. **📊 CLI Status Command (	tlshield status)**
   - View live stats (total packets, modified TTL count, split TCP packets) directly from terminal.

---

## 📥 Installation

### Method 1: Magisk / KernelSU / APatch App
1. Download the latest GKI_Hotspot_Shield_v3.0.zip from [Releases](https://github.com/maozdemir/gki-hotspot-shield/releases).
2. Open **Magisk / KernelSU / APatch**.
3. Go to **Modules** $\rightarrow$ **Install from storage** $\rightarrow$ Select the ZIP file.
4. Reboot your device.

---

## 🛠️ Building from Source

### Requirements
- Go 1.22+

### Cross-Compilation (ARM64)
`ash
# Windows PowerShell
$env:GOOS="linux"; $env:GOARCH="arm64"; go build -ldflags="-s -w" -o nfqttl main.go

# Linux / macOS
GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o nfqttl main.go
`

---

## 📄 License
This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
