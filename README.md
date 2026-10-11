
# Pi Travel Router

A lightweight Raspberry Pi travel router built using Bash, `hostapd`, `dnsmasq`, and Linux networking tools without NetworkManager.

## Network Layout

```text
Internet
   |
eth0 / wlan0         Upstream connections
   |
Raspberry Pi         IPv4 forwarding + iptables NAT
   |
wlan1 (10.10.10.1)  WPA2 Access Point + DHCP
   |
Phone / Laptop
```

## Current Functionality

- Bash-based access point initialization and daemon management
- MAC address randomization on `wlan1`
- WPA2 access point using `hostapd`
- DHCP server using `dnsmasq`
- Static AP address: `10.10.10.1/24`
- DHCP range: `10.10.10.5` – `10.10.10.20` (5-hour leases)
- IPv4 forwarding configuration checks
- `iptables` NAT masquerading and forwarding for `eth0` and `wlan0`
- DHCP exit-hook logic for routing metrics (`eth0`: 100, `wlan0`: 200)
- Daemon startup and readiness checks

## Project Files

| File | Description |
|---|---|
| `start-AP.sh` | Initializes the AP, forwarding rules, and network daemons |
| `randomize-mac.sh` | Randomizes the MAC address of `wlan1` |
| `hostapd.conf` | WPA2 access point configuration |
| `dnsmasq.conf` | DHCP server configuration |
| `route-metrics` | DHCP exit hook for route metrics |
| `index.html` | HTML dashboard prototype |
| `docs/Pi Travel Router.md` | Development and troubleshooting notes |

## Usage

The scripts require the appropriate networking packages and configuration files to be installed.

Run from the repository directory:

```bash
sudo bash start-AP.sh
```

The script configures `wlan1`, checks IPv4 forwarding, applies iptables rules, and starts `dnsmasq` and `hostapd`.

The `route-metrics` file is separate from the main startup script and must be installed as a DHCP exit hook to execute on lease events.


