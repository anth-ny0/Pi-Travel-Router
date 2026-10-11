# Pi Travel Router

A lightweight Raspberry Pi travel router using Bash and Linux networking tools without NetworkManager.

The project uses `wlan1` to host a wireless access point, with `hostapd` handling Wi-Fi authentication and `dnsmasq` providing DHCP.

## Network Layout

```text
Raspberry Pi
├── wlan0 — External Wi-Fi interface
└── wlan1 — Wireless Access Point
             ├── hostapd (WPA2)
             └── dnsmasq (DHCP)
```

## Current Functionality

- Bash-based access point initialization
- MAC address randomization on `wlan1`
- WPA2 access point using `hostapd`
- DHCP server using `dnsmasq`
- Static IP configuration (`10.10.10.1/24`)
- DHCP address range (`10.10.10.5` – `10.10.10.20`)
- IPv4 forwarding configuration checks
- Process startup and readiness checks

## Files

| File | Description |
|---|---|
| `start-AP.sh` | Initializes the interface and starts the AP services |
| `randomize-mac.sh` | Randomizes the MAC address of `wlan1` |
| `hostapd.conf` | WPA2 access point settings |
| `dnsmasq.conf` | DHCP server settings |
| `index.html` | HTML interface prototype |

## Usage

The scripts require `hostapd`, `dnsmasq`, `macchanger`, and the appropriate wireless interface configuration.

Run from the repository directory:

```bash
sudo bash start-AP.sh
```

The script configures `wlan1`, checks IPv4 forwarding, and starts `dnsmasq` and `hostapd`.

