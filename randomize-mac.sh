## Randomize wlan1 mac address before starting Hostapd.

check(){
	iw dev wlan1 info 2&>1 /dev/null
	EXIT=$?
	if [[ $EXIT == 237 ]]; then
		echo "[-] wlan1 doesn't exist!"
		exit 1
	fi
}
randomize(){
	sudo ip link set wlan1 down
	sudo macchanger -r wlan1 > /dev/null 
	sudo ip link set wlan1 up
	exit 0
}

if check; then
	randomize
else
	exit 1
fi
