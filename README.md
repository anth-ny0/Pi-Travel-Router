Pi Travel Router
A Raspberry Pi travel router that shares an internet connection through its own Wi-Fi access point, with WireGuard VPN support.
- wlan0 — connects to an existing Wi-Fi network
- wlan1 — USB Wi-Fi adapter that broadcasts your AP
- eth0 — wired connection (preferred uplink when available)
- wg0 — WireGuard tunnel
Build your own router image
You'll need a Raspberry Pi, a compatible USB Wi-Fi adapter, and a Linux computer with Docker.
git clone https://github.com/anth-ny0/Pi-Travel-Router.git
cd Pi-Travel-Router/build-router
1. Customize the AP
Edit build-router/configs/hostapd.conf (paths here are relative to the repository root):
interface=wlan1
ssid=MyTravelRouter
wpa_passphrase=ChangeThisPassword
hw_mode=g
channel=6
Set your AP name, password (8–63 characters), and Wi-Fi channel. Leave the other existing settings in the file.
2. Customize DHCP
Edit build-router/configs/dnsmasq.conf:
interface=wlan1
dhcp-range=10.10.10.5,10.10.10.20,5h
dhcp-option=option:router,10.10.10.1
dhcp-option=option:dns-server,10.10.10.1
- dhcp-range — IP addresses given to clients and lease duration.
- option:router — default gateway advertised to clients.
- option:dns-server — DNS server advertised to clients.
The AP IP address is set to 10.10.10.1/24 in build-router/scripts/start-AP.sh. If you change the subnet, also update that IP and the DHCP gateway/DNS settings. Only advertise the Pi as DNS if it can resolve queries.
3. Customize the image
Edit build-router/config.pkrvars.hcl:
Setting	Purpose
admin_password	Password for the user account
image_name	Output filename (default: travel-router.img)
timezone, locale, keyboard_layout	Regional settings
packages	Packages installed in the image
termcolor	Terminal prompt color


Other files you may want to change:
File	Purpose
build-router/configs/01-netplan.yaml	Interface IPs and route priorities
build-router/scripts/start-AP.sh	AP startup, NAT, forwarding, and VPN startup
build-router/services/startap.service	AP auto-start at boot
build-router/raspbian.pkr.hcl	Base OS image and image size


WireGuard: Place your existing wg0.conf at build-router/crypto/wg0.conf before building. The builder copies it to /etc/wireguard/wg0.conf. Keep private keys out of Git: crypto/ is gitignored.
4. Build and flash
From inside build-router/:
chmod +x build.sh
./build.sh
The Docker/Packer build produces the .img file in build-router/. In Raspberry Pi Imager, select Use custom, choose the generated image, and flash it to your SD card.
Using the router
1. Boot the Pi with the USB AP adapter attached. Connect eth0 to an internet uplink, or set up upstream Wi-Fi on wlan0.
2. For a Wi-Fi uplink, SSH into the Pi and run sudo /opt/xbin/wifi-client.sh to select a network.
3. Connect your phone or laptop to the SSID you set in hostapd.conf.
The image enables startap.service, which runs the AP startup script after its internet connectivity check succeeds.

Useful Pi commands:
sudo systemctl status startap.service  # AP startup status
sudo journalctl -u startap.service -b  # Startup logs
sudo wg show                            # WireGuard status
ip route get 8.8.8.8                    # Check route to the internet
Note: For newly built images, edit the files inside build-router/, not the standalone copies at the repository root. See [the detailed image builder README](build-router/README.md) for more build information.
