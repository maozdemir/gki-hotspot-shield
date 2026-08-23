# 🛡️ GKI Hotspot Shield & TTL/DPI Fixer

[![Release](https://img.shields.io/github/v/release/maozdemir/gki-hotspot-shield?style=flat-square)](https://github.com/maozdemir/gki-hotspot-shield/releases)
[![Build and Release](https://github.com/maozdemir/gki-hotspot-shield/actions/workflows/build.yml/badge.svg)](https://github.com/maozdemir/gki-hotspot-shield/actions)
[![License](https://img.shields.io/badge/License-GPL%203.0-blue.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20GKI%20(12%2B)-green.svg?style=flat-square)](https://source.android.com/docs/core/architecture/kernel/generic-kernel-image)

An all-in-one network engine, DPI bypass suite, and root module designed specifically for modern Android devices running Generic Kernel Image (GKI) kernels (Android 12, 13, 14, 15, and 16+ on Snapdragon 8 Gen 2/3/4, Dimensity, Tensor, Exynos).

---

## 🌟 Why This Project?

On modern Android GKI kernels (kernel versions 5.4, 5.10, 5.15, 6.1, 6.6, 6.12+), Google completely removed the traditional Netfilter kernel target `CONFIG_IP_NF_TARGET_TTL` and `CONFIG_IP6_NF_TARGET_HL`. As a result, classic `iptables -t mangle -j TTL --ttl-set 64` rules fail with:

```text
Warning: Extension TTL revision 0 not supported, missing kernel module?
iptables: No chain/target/match by that name.
```

Furthermore, older C-based modules rely on standard Linux routing table 254 (main table) to locate the gateway interface. On modern Android (12+), mobile data routes are stored in dynamic policy routing tables (`table 1000+`), which caused older tools to silently fail and leak tethered TTL values (127/128).

**GKI Hotspot Shield** solves this natively without needing custom kernel recompilations by leveraging `NFQUEUE` (Netfilter Netlink Queue) and a high-performance, real-time pure Go engine.

---

## 🚀 Key Features

### 1. ⚡ Real-Time TTL & Hop Limit Normalization (TTL=64)
- Normalizes IPv4 TTL and IPv6 Hop Limit to `64` in microseconds with zero perceptible latency.
- Automatically recalculates IPv4 header checksums.
- Operates at real-time priority (`nice -20`) with 4MB Netlink buffer allocation to prevent packet loss under full Gigabit Wi-Fi 7 / 5G speeds.

### 2. 🔒 Transparent Encrypted DNS-over-HTTPS (DoH Proxy)
- Intercepts all unencrypted UDP & TCP port 53 DNS queries coming from connected laptops, phones, consoles, and smart TVs via `iptables REDIRECT`.
- Resolves queries over encrypted **TLS 1.3 / HTTPS** (RFC 8484) to your preferred upstream provider:
  - **Cloudflare** (`1.1.1.1`)
  - **Quad9 Security** (`9.9.9.9` - malware & phishing protection)
  - **Google DNS** (`8.8.8.8`)
  - **AdGuard DNS** (`94.140.14.14` - ad & tracker blocking)
- **Ultra-fast In-Memory Cache:** Cached domain lookups respond in `<0.2 ms`.
- **Zero Configuration:** Connected devices need no manual DNS changes; protection is transparent and network-wide.

### 3. 🛡️ GoodbyeDPI / Zapret TLS ClientHello TCP Segmentation
- Inspects initial HTTPS TLS ClientHello (SNI) and HTTP request packets.
- Splits the TCP payload into segments at byte-level using raw socket injection to bypass Deep Packet Inspection (DPI), carrier throttling, and OS fingerprinting.
- Network-wide DPI evasion for all tethered clients (Windows, Mac, iOS, Android, Linux, PlayStation, Xbox).

### 4. 📱 In-App WebUI Dashboard & Magisk Action Button
- **Zero App Drawer Clutter:** No launcher icons or unnecessary APKs.
- **Magisk Action Launcher:** Tapping the **Action** button on the module card inside Magisk app instantly launches the Material 3 dashboard (`http://127.0.0.1:64640`).
- **KernelSU / APatch / MMRL WebUI:** Supports native embedded WebView via `webroot/index.html`.
- **Live Telemetry:** Real-time counters for Total Packets, TTL 64 Fixes, DPI TCP Splits, DoH Queries, and DNS Cache Hits.
- **Instant Configuration:** Adjust settings and reload the daemon with one click.

### 5. 🎮 Anti-Bufferbloat QoS (`fq_codel`)
- Applies Fair Queueing with Controlled Delay (`fq_codel`) on active network interfaces.
- Isolates ping/gaming packets from large video streaming and download flows, keeping gaming ping stable during 4K streaming or background downloads.

### 6. 🔋 Smart Hotspot-Aware Wi-Fi Battery Guard
- Automatically disables Wi-Fi power saving (`power_save off`) **only** while hotspot is active (preventing latency jitter when the screen turns off).
- Instantly restores normal Wi-Fi power saving (`power_save on`) when hotspot is turned off to preserve battery life.

### 7. 📲 Carrier DUN & Entitlement Bypass
- Automatically resets Android carrier entitlement flags: `tether_dun_required=0`, `net.tethering.noprovisioning=true`, and `tether_entitlement_check_state=0`.
- Enforces kernel default TTLs: `net.ipv4.ip_default_ttl=64` and `net.ipv6.conf.all.hop_limit=64`.

---

## ⚙️ Configuration (`config.conf`)

Settings can be changed either via the **WebUI Dashboard** or directly in `/data/adb/modules/nfqttl/config.conf`:

```ini
# ==========================================
# GKI Hotspot Shield & Optimizer Config
# ==========================================

# Target TTL & Hop Limit (Default: 64)
TARGET_TTL=64

# DPI Evasion / TCP Segmentation (Zapret / GoodbyeDPI mode)
TCP_SPLIT=1
SPLIT_POS=2
QUEUE_NUM=6464

# Transparent Encrypted DNS (DNS-over-HTTPS)
DOH_ENABLED=1
DOH_PROVIDER=cloudflare   # Options: cloudflare, quad9, google, adguard

# Bufferbloat & Ping Protection (fq_codel QoS)
BUFFERBLOAT_QOS=1

# Wi-Fi Power Save Lock (Prevents jitter/sleep when screen is off)
WIFI_POWER_SAVE_LOCK=1

# TCP Low Latency & Fast Buffer Flushing
TCP_LOW_LATENCY=1
```

---

## 📥 Installation

### Method 1: Magisk / KernelSU / APatch
1. Download the latest `GKI_Hotspot_Shield_v*.zip` from [Releases](https://github.com/maozdemir/gki-hotspot-shield/releases).
2. Open **Magisk**, **KernelSU**, or **APatch**.
3. Navigate to **Modules** $\rightarrow$ **Install from storage** $\rightarrow$ Select the downloaded ZIP.
4. Reboot your device.

### Method 2: Launching Configuration Dashboard
- **In Magisk:** Open Magisk $\rightarrow$ Modules $\rightarrow$ Tap the **Action** button on the `GKI Hotspot Shield` card.
- **In Browser:** Navigate to `http://127.0.0.1:64640` on your phone.
- **In Terminal:** Run `ttlshield status` in Termux (as root) to view live statistics.

---

## 🛠️ Building from Source

### Requirements
- Go 1.22+
- PowerShell (Windows) or Bash (Linux / macOS)

### Cross-Compilation (ARM64)
```bash
# Windows PowerShell
$env:GOOS="linux"; $env:GOARCH="arm64"; go build -ldflags="-s -w" -o nfqttl main.go

# Linux / macOS
GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o nfqttl main.go
```

---

## 📄 License
This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
