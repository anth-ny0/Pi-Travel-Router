# Figuring out how Hostapd works:
Hostapd is a daemon that esentially enables a wireless interface card to act as an Access Point that handles all the processes for authentication an client messages.

I started with getting a templated hostapd.conf file online from here.
[hostapd conf template](https://nims11.wordpress.com/2012/04/27/hostapd-the-linux-way-to-create-virtual-wifi-access-point/)

> Setup a hostapd.conf file with the following settings:
```bash
interface=wlan1
driver=nl80211
ssid=TEST-AP
hw_mode=g
channel=6
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=3
wpa_passphrase=password
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
```

>Then I started hostapd service and saw this in my Wi-Fi settings on my phone.
```bash
sudo systemctl start hostapd
```

Now I know the AP was working as intended running on my wlan1 interface.

![[IMG_2874.jpeg]]

When I would try to connect to the AP on my iPhone I would get an error  saying incorrect Password, I know the password is set from the config and I wasnt making any typos so I assumed it was because my iPhone could get an IP so it was failing.

![[Pasted image 20261011131712.png]]

but in the hostapd status I could see I was authenticating.

This leads us into the next step.

# Figuring out how dnsmasq works:

Okay dnsmasq is the daemon that runs a DHCP server on the specified interface. In my case wlan1 is the NIC that will be hosting the AP and the DHCP server. You have to make a dnsmasq.conf to specify the interface, the dhcp-range for ip allocation, and the lease time. This was my basic configuration:

```bash
interface=wlan1
dhcp-range=10.10.10.5,10.10.10.20,5h
```
- This is saying to use the wlan1 interface.
- And the IP range is set from 10.10.10.5 - 10.10.10.20 with a lease time of  5 hours.

I had a few errors where I would run the DHCP server and  hostapd and it would still say "Incorrect Password" when i tried to asssociate to the "TEST-AP" network.

My original hostapd.conf had `wpa=3` which is WPA an WPA2 authentication, I changed it to `wpa=2` which is just WPA2 encryption and  stopped and started dnsmasq and hostapd in that order and i was able to authenticate and associate to the network and was dished an IP from my DHCP server!

# Scripts
I write the randmize-mac.sh and the start-AP.sh and realized there was an issue when I would stop and restart hostapd and dnsmasq that my phone would not reliably connect back to the new BSSID of the AP, using the assistance of AI. I narrowed it down to the fact that since my BSSID was being randomized on each initializaiton my phone was having a hard time realizing the BSSID was different causing the "Incorrect Password" issue. By removing `sudo ip link set wlan1 up` from my mac randomizer script and allowing hostapd to initialize the interface that seemed to fix the issue.
# Links and other info:
#### Github Repo
[Git](https://github.com/anth-ny0/Pi-Travel-Router)
#### OS-Release
```
user@raspberrypi:~ $ cat /etc/os-release 
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.7
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

