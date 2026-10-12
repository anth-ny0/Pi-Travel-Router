## Starting hostapd and dnsmasq

EXIT_CODE(){
	if [[ ${EXIT} == 1 ]]; then
		echo "[-] Failed to start process!"
	else
		echo "[+] Process started sucessfully!"
	fi
}


## Randomize the MAC address

RANDOMIZE(){
	if ./randomize-mac.sh; then
		MAC=$(iw dev wlan1 info | awk '/addr/ {print $2}')
		echo "[+] Mac randomized to [${MAC}]!"
		sleep 1
	fi
}

## Configure Statis IP on wlan1
WLAN(){
	if ! ip -4 addr show wlan1 | grep -q '10.10.10.1/24'; then
		sudo ip addr replace 10.10.10.1/24 dev wlan1
		echo "[+] WLAN1 configured!"
	fi
}


#Configure IPtables rules

IPTABLES() {
    echo "[*] Configuring iptables..."

    for IFACE in eth0 wlan0; do

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


## Connecting wlan0 to an actual network.

#enabes the use of wpa_cli
echo "ctrl_interface=/run/wpa_supplicant
update_config=0" > wlan0.conf 


# Start Supplicant

SUPPLICANT(){
	#Check if wired connection
	echo "[*] Testing Ethernet!"
	if [[ $(cat /sys/class/net/eth0/carrier 2>/dev/null) == 1 ]] &&
		ping -I eth0 -c 2 -W 2 1.1.1.1 &>/dev/null; then
		echo "[+] Ethernet has internet!"
		exit 0
	else
		echo "[-] Ethernet unavailable. Using Wi-Fi."
	    
	fi

	echo "[*] Starting wpa_supplicant..."

	if pgrep -x wpa_supplicant >/dev/null; then
		sudo killall wpa_supplicant 
		sleep 5
		sudo wpa_supplicant -B -i wlan0 -c wlan0.conf >/dev/null
	else
		sudo wpa_supplicant -B -i wlan0 -c wlan0.conf >/dev/null
	fi

	echo "[+] wpa_supplicant successfull started!"
	sleep 3

	echo "[*] Scanning for local networks!"
	sudo wpa_cli -i wlan0 scan > /dev/null
	sleep 3
	NETWORKS=$(sudo wpa_cli -i wlan0 scan_results | awk '{print $5}' | uniq)

	PS3="Select a Network: "
	select NETWORK in ${NETWORKS}; do
		echo "You chose: ${NETWORK}"
	       	read -rp "Password: " PASS
		break
	done

	# Setup connection!

	ID=$(sudo wpa_cli -i wlan0 add_network)

	sudo wpa_cli -i wlan0 set_network "$ID" ssid "\"$NETWORK\""
	sudo wpa_cli -i wlan0 set_network "$ID" psk "\"$PASS\""
	sudo wpa_cli -i wlan0 select_network "$ID"
	until sudo wpa_cli -i wlan0 status | grep -q '^wpa_state=COMPLETED$'; do
		sleep 1
	done
	
       	echo "[+] Connected to $NETWORK"
}



#RANDOMIZE || exit 1
WLAN || exit 1
FORWARDING || exit 1
IPTABLES || exit 1
DNSMASQ || exit 1
HOSTAPD || exit 1
SUPPLICANT || exit 1
