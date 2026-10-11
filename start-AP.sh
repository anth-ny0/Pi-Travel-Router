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
		sudo ip link set wlan1 up
		echo "[+] WLAN1 configured!"
	fi
}

## Start Hostapd

HOSTAPD(){
	if pgrep -x hostapd 1>/dev/null; then
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
	if pgrep -x dnsmasq 1>/dev/null; then
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



RANDOMIZE || exit 1
WLAN || exit 1
FORWARDING || exit 1
DNSMASQ || exit 1
HOSTAPD || exit 1

