

## Connecting wlan0 to an actual network.

#enabes the use of wpa_cli
echo "ctrl_interface=/run/wpa_supplicant
update_config=0" > wlan0.conf 

#Check if wired connection
echo "[*] Testing Ethernet!"
if [[ $(cat /sys/class/net/eth0/carrier 2>/dev/null) == 1 ]] &&
   ping -I eth0 -c 2 -W 2 1.1.1.1 &>/dev/null; then

    echo "[+] Ethernet has internet!"
else
    echo "[-] Ethernet unavailable. Using Wi-Fi."
    
fi

# Start Supplicant

SUPPLICANT(){
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
	NETWORKS=$(sudo wpa_cli -i wlan0 scan_results | awk '{print $5}')

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
	
}


SUPPLICANT
