#!/usr/bin/bash


check_process(){
	
	pgrep -x hostapd > /dev/null
	EXIT1=$?
	pgrep -x dnsmasq > /dev/null
	EXIT2=$?

	if [[ $EXIT1 -eq 1 || $EXIT2 -eq 1 ]]; then
		echo "[+] Travel Router is already Down!"
		exit 0
	fi


}

kill_router(){

	echo "[+] Stopping Pi-Travel-Router!"

	sudo pkill dnsmasq && sudo pkill hostapd
	sleep 5

	echo "[*] Turning off ACCESS POINT..."
	sleep 3

	echo "[*] Turning off DHCP SERVER..."
	sleep 3

	echo "[+] Pi-Travel-Router is DOWN!"
}
check_process || exit 1
kill_router || exit 1
