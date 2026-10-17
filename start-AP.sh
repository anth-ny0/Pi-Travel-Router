#!/bin/bash
## Configure Statis IP on wlan1
WLAN(){
	if ! ip -4 addr show wlan1 | grep -q '10.10.10.1/24'; then
		sudo ip addr replace 10.10.10.1/24 dev wlan1
		echo "[+] WLAN1 configured!"
	fi
}

# Start WG TUN

START_WG(){
	echo "[*] Starting Wireguard..."
	sudo systemctl start wg-quick@wg0 > /dev/null

	if ! sudo wg > /dev/null; then
		echo "[-] Failed to start Wireguard @ wg0"
		exit 1
	fi


}



#Configure IPtables rules

IPTABLES() {
    echo "[*] Configuring iptables..."

    for IFACE in eth0 wlan0 wg0; do

        # NAT masquerading
        sudo iptables -t nat -C POSTROUTING -s 10.10.10.0/24 -o "$IFACE" -j MASQUERADE 2>/dev/null || sudo iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o "$IFACE" -j MASQUERADE || return 1

        # Allow outbound traffic from wlan1
        sudo iptables -C FORWARD -i wlan1 -o "$IFACE" -s 10.10.10.0/24 -j ACCEPT 2>/dev/null || sudo iptables -A FORWARD -i wlan1 -o "$IFACE" -s 10.10.10.0/24 -j ACCEPT || return 1

        # Allow established return traffic
        sudo iptables -C FORWARD -i "$IFACE" -o wlan1 -d 10.10.10.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || sudo iptables -A FORWARD -i "$IFACE" -o wlan1 -d 10.10.10.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT || return 1

    done

    echo "[+] iptables configured successfully!"
}

## Start Hostapd

HOSTAPD(){
	if pgrep -x hostapd; then
		echo "Hostapd is already running! RESTARTING!"
		sudo pkill -x hostapd

		while pgrep -x hostapd >/dev/null; do
		    sleep 0.2
		done

		sudo hostapd -B -dd -f /var/log/hostapd.log /etc/hostapd/hostapd.conf
		echo "[*] Waiting for hostapd..."

		until sudo hostapd_cli -i wlan1 status 2>/dev/null | grep -q '^state=ENABLED$'; do
			sleep 1
		done
		echo "[+] Hostapd successfully started!"
	else
		echo "[+] Starting Hostapd!"
		sudo hostapd -B -dd -f /var/log/hostapd.log /etc/hostapd/hostapd.conf
		echo "[*] Waiting for hostapd..."
		
		until sudo hostapd_cli -i wlan1 status 2>/dev/null | grep -q '^state=ENABLED$'; do
			sleep 1
		done
		echo "[+] Hostapd successfully started!"
	fi

}


## Start dnsmasq
DNSMASQ(){
	if pgrep -x dnsmasq; then
		echo "dnsmasq is already running! RESTARTING!"
		sudo pkill -x dnsmasq 

		while pgrep -x dnsmasq >/dev/null; do
		    sleep 0.2
		done

		sudo dnsmasq --log-facility=/var/log/dnsmasq.log 
		echo "[*] Waiting for dnsmasq..."

		until ss -ptuna 2>/dev/null | grep -q :67; do
			sleep 1
		done
		echo "[+] dnsmasq successfully started!"
	
	else
		echo "Starting dnsmasq!"
		sudo dnsmasq --log-facility=/var/log/dnsmasq.log
		sleep 2

		echo "[*] Waiting for dnsmasq..."

		until ss -ptuna 2>/dev/null | grep -q :67; do
			sleep 1
		done
		echo "[+] dnsmasq successfully started!"

	fi

}

FORWARDING(){
	local CHECK_NUM=$(sudo sysctl -p | awk '{print $3}')
	
	echo "[*] Checking IP Forwarding!"
	sleep 1

	if [[ ${CHECK_NUM} == 0 ]]; then 
		echo" [+] Setting IP Forwarding to 1!"
		sleep 1
		sudo sysctl -w net.ipv4.ip_forward=1
		echo "[+] IP Forwarding set to 1!"
	else
		echo "[+]IP Forwarding is already set to 1!"
	fi
}




WLAN || exit 1
START_WG || exit 1
FORWARDING || exit 1
IPTABLES || exit 1
DNSMASQ || exit 1
HOSTAPD || exit 1
