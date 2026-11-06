#!/bin/bash
## Put things in here that must run after the Packer provisioners do their work and copy in external files.

LOG_DIR="/opt/src/logs"
LOG_FILE="$LOG_DIR/provision-pi.log"

mkdir -p $LOG_DIR
touch $LOG_FILE

# Function to append output to the log file
log() {
    echo "[$(date --rfc-3339=seconds)]: $*" | tee -a "$LOG_FILE"
}

log "------------------Starting post.sh Script...--------------------"

# Set frontend to non-interactive to avoid prompts during package installations
export DEBIAN_FRONTEND=noninteractive

log "------------------Enabling SSH...------------------"
touch /boot/ssh 2>&1 | tee -a "$LOG_FILE"

#log "------------------Disabling Bluetooth...------------------"
#echo "dtoverlay=disable-bt" >> /boot/config.txt 2>&1 | tee -a "$LOG_FILE"

#log "------------------Disabling WiFi...------------------"
#echo "dtoverlay=disable-wifi" >> /boot/config.txt 2>&1 | tee -a "$LOG_FILE"

log "------------------Removing first boot wizard user...------------------"
userdel -r rpi-first-boot-wizard 2>&1 | tee -a "$LOG_FILE"
userdel -r pi 2>&1 | tee -a "$LOG_FILE"

log "------------------Enabling zswap...------------------"
sed -i -e 's/$/ zswap.enabled=1 rfkill.default_state=0/' /boot/cmdline.txt 2>&1 | tee -a "$LOG_FILE"

log "------------------Enabling automatic rootfs expansion on first boot...------------------"
wget -O /etc/init.d/resize2fs_once https://raw.githubusercontent.com/RPi-Distro/pi-gen/master/stage2/01-sys-tweaks/files/resize2fs_once 2>&1 | tee -a "$LOG_FILE"
chmod +x /etc/init.d/resize2fs_once 2>&1 | tee -a "$LOG_FILE"
systemctl enable resize2fs_once 2>&1 | tee -a "$LOG_FILE"

log "------------------Skipping initial setup wizard...------------------"
echo "pi ALL=NOPASSWD: /usr/sbin/raspi-config, /sbin/shutdown" > /etc/sudoers.d/piwiz 2>&1 | tee -a "$LOG_FILE"
rm /etc/xdg/autostart/piwiz.desktop 2>&1 | tee -a "$LOG_FILE"

#log "------------------Setting up Real Time Clock...------------------"
#raspi-config nonint do_i2c 0 2>&1 | tee -a "$LOG_FILE"
#echo "dtoverlay=i2c-rtc,ds3231" >> /boot/config.txt 2>&1 | tee -a "$LOG_FILE"
#systemctl disable fake-hwclock 2>&1 | tee -a "$LOG_FILE"
#rm -f /etc/cron.hourly/fake-hwclock 2>&1 | tee -a "$LOG_FILE"


log "------------------Setting up locale, keyboard layout, and timezone...------------------"
raspi-config nonint do_change_locale ${LOCALE} 2>&1 | tee -a "$LOG_FILE"
raspi-config nonint do_configure_keyboard ${KEYBOARD_LAYOUT} 2>&1 | tee -a "$LOG_FILE"
raspi-config nonint do_change_timezone ${TIMEZONE} 2>&1 | tee -a "$LOG_FILE"
raspi-config nonint do_wifi_country US 2>&1 | tee -a "$LOG_FILE"

log "------------------Enable custom systemd services------------------"
systemctl enable iw-reg.service 2>&1 | tee -a "$LOG_FILE"
systemctl enable startap.service 2>&1 | tee -a "$LOG_FILE"
systemctl disable hostapd 2>&1 | tee -a "$LOG_FILE"

log "------------------Enabling IP Forwarding...------------------"
netplan apply

log "------------------Enabling IP Forwarding...------------------"
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf 2>&1 | tee -a "$LOG_FILE"
sysctl -p 2>&1 | tee -a "$LOG_FILE"


log "------------------SSH Hardening...------------------"
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config 2>&1 | tee -a "$LOG_FILE"
sed -i 's/^#\?GatewayPorts.*/GatewayPorts yes/' /etc/ssh/sshd_config 2>&1 | tee -a "$LOG_FILE"
sed -i 's/^#\?PermitTunnel.*/PermitTunnel yes/' /etc/ssh/sshd_config 2>&1 | tee -a "$LOG_FILE"

log "------------------System cleanup...------------------"
apt-get autoremove -y 2>&1 | tee -a "$LOG_FILE"
apt-get clean 2>&1 | tee -a "$LOG_FILE"

log "------------------Setup FSTAB...------------------"
echo '/dev/sda1 /opt/logs ntfs nofail 0 2' >> /etc/fstab

log "------------------Install AngryOxide Latest...------------------"
mkdir -p /opt/ao
cd /opt/ao
curl -A curl -sL $(curl -A curl -s https://api.github.com/repos/ragnt/angryoxide/releases/latest | grep "http.*linux-aarch64-musl.tar.gz" | awk '{print $2}' | sed 's|[\"\,]*||g') | tar -xz
chmod +x install.sh # Make executable
./install.sh install # Install (as root, including zsh/bash completions)
cd /opt
rm -rf ao

log "------------------Disable Autologin...------------------"
sed -i '/^autologin-user=/ s/^/# /' /etc/lightdm/lightdm.conf 2>&1 | tee -a "$LOG_FILE"
rm '/etc/systemd/system/getty@tty1.service.d/autologin.conf'

sed -i.bak '/secure_path/c\Defaults secure_path="/opt/tools:/opt/xbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:"' /etc/sudoers

log "------------------Set Multi-User Target...------------------"
systemctl set-default multi-user.target 2>&1 | tee -a "$LOG_FILE"
systemctl disable userconfig 2>&1 | tee -a "$LOG_FILE"
systemctl enable getty@tty1 2>&1 | tee -a "$LOG_FILE"

sed -i s/REPLACEME/${TERMCOLOR}/g /home/user/.bashrc
sed -i s/REPLACEME/${TERMCOLOR}/g /root/.bashrc

log "------------------Provisioning complete.------------------"


