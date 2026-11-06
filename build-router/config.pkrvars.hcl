# User login password
admin_password = "user"

# Image Name (avoid spaces for best results)
image_name = "travel-router.img"

# Timezone Info - Use TZ identifier in Region/City format
#timezone = "America/New_York"
timezone = "UTC"

# Locale Info
locale = "en_US.UTF-8"

# Keyboard Layout 
keyboard_layout = "us"

# Apt Install Package List
packages = [
    "cryptsetup",
    "fail2ban", 
    "minicom",
    "ntp",
    "ethtool", 
    "curl", 
    "wget", 
    "gnupg2", 
    "sqlite3", 
    "git", 
    "python3-pip", 
    "tshark", 
    "traceroute", 
    "tcptraceroute", 
    "vim", 
    "proxychains",
    "hcxtools",
    "macchanger", 
    "nmap", 
    "tcpdump", 
    "wavemon", 
    "tmux", 
    "netcat-openbsd", 
    "socat",
    "gpsd",
    "netplan.io",
    "gpsd-clients",
    "python3-smbus",
    "i2c-tools",
    "iptables",
    "wpasupplicant",
    "dnsmasq",
    "hostapd",
    "wireguard"
]

# Set the terminal prompt Color Options are: red, yellow, blue, magenta, black, cyan
termcolor = "blue" 
