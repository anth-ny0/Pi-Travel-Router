#!/bin/bash
## Put things in here that must occur before we copy a bunch of system files over with Packer.
## This should typically include things like creating directories and installing packages.

LOG_DIR="/opt/src/logs"
LOG_FILE="$LOG_DIR/provision-pi.log"

mkdir -p $LOG_DIR
touch $LOG_FILE
# Function to append output to the log file
log() {
    echo "[$(date --rfc-3339=seconds)]: $*" | tee -a "$LOG_FILE"
}
log "------------------Starting pre.sh Script...--------------------"


log "------------------Starting provisioning...--------------------"

# Set frontend to non-interactive to avoid prompts during package installations
export DEBIAN_FRONTEND=noninteractive

log "------------------Setup Tools Dir...------------------"
mkdir -p /opt/tools
touch /opt/tools/NOTMOUNTED
chown -R :sudo /opt/tools
chmod -R g+w /opt/tools

log "------------------Setup Tools Dir...------------------"
mkdir -p /opt/xbin
chown -R :sudo /opt/xbin
chmod -R g+w /opt/xbin

log "------------------Setup Source Dir...------------------"
mkdir -p /opt/src
chown -R :sudo /opt/src
chmod -R g+w /opt/src

log "------------------Setup Logs Dir...------------------"
touch /opt/logs/NOTMOUNTED
chown -R :sudo /opt/logs
chmod -R g+w /opt/logs

log "------------------Creating new user...------------------"
set +H
export NEW_PASSWD="${ADMIN_PASSWORD}" # Set in config.pkr.hcl
echo "Using user password: ${ADMIN_PASSWORD}" >> "$LOG_FILE"
export HASHED_PASSWD="$(openssl passwd -6 ${NEW_PASSWD})"

useradd -m -s /bin/bash user
echo "user:${HASHED_PASSWD}" | chpasswd -e 2>&1 | tee -a "$LOG_FILE"
usermod -aG sudo user 2>&1 | tee -a "$LOG_FILE"
set -H

log "------------------Stop problem services...------------------"
systemctl disable systemd-timesyncd.service 2>&1 | tee -a "$LOG_FILE"
systemctl mask systemd-timesyncd.service 2>&1 | tee -a "$LOG_FILE"

systemctl disable wpa_supplicant.service 2>&1 | tee -a "$LOG_FILE"
systemctl mask wpa_supplicant.service 2>&1 | tee -a "$LOG_FILE"

systemctl disable NetworkManager 2>&1 | tee -a "$LOG_FILE"
systemctl mask NetworkManager 2>&1 | tee -a "$LOG_FILE"

systemctl disable avahi-daemon.service 2>&1 | tee -a "$LOG_FILE"
systemctl mask avahi-daemon.service 2>&1 | tee -a "$LOG_FILE"

systemctl disable systemd-rfkill.service 2>&1 | tee -a "$LOG_FILE"
systemctl mask systemd-rfkill.service 2>&1 | tee -a "$LOG_FILE"

systemctl disable systemd-rfkill.socket 2>&1 | tee -a "$LOG_FILE"
systemctl mask systemd-rfkill.socket 2>&1 | tee -a "$LOG_FILE"

log "------------------Enable good services...------------------"
systemctl enable systemd-networkd.service 2>&1 | tee -a "$LOG_FILE"

log "------------------Updating the system...------------------"
apt-get update 2>&1 | tee -a "$LOG_FILE"
#apt-get upgrade -y 2>&1 | tee -a "$LOG_FILE"
apt-get autoremove -y 2>&1 | tee -a "$LOG_FILE"
apt-get clean 2>&1 | tee -a "$LOG_FILE"

log "------------------Installing applications...------------------"
apt install -y --no-install-recommends ${APT_PACKAGES} 2>&1 | tee -a "$LOG_FILE"

