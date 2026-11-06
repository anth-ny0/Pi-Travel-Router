source "arm" "raspbian" {
  file_urls             = ["https://downloads.raspberrypi.com/raspios_arm64/images/raspios_arm64-2025-05-13/2025-05-13-raspios-bookworm-arm64.img.xz"]
  file_checksum_url     = "https://downloads.raspberrypi.com/raspios_arm64/images/raspios_arm64-2025-05-13/2025-05-13-raspios-bookworm-arm64.img.xz.sha256"
  #file_urls             = ["https://downloads.raspberrypi.com/raspios_full_arm64/images/raspios_full_arm64-2025-05-13/2025-05-13-raspios-bookworm-arm64-full.img.xz"]
  #file_checksum_url     = "https://downloads.raspberrypi.com/raspios_full_arm64/images/raspios_full_arm64-2025-05-13/2025-05-13-raspios-bookworm-arm64-full.img.xz.sha256"
  file_checksum_type    = "sha256"
  file_target_extension = "xz"
  file_unarchive_cmd    = ["xz", "-d", "$ARCHIVE_PATH"]
  image_build_method    = "resize" # Should allow resizing, set 'reuse' for normal mode
  image_path            = var.image_name 
  image_size            = "6.5G"
  image_type            = "dos"

  image_partitions {
    filesystem   = "fat"
    start_sector = "8192"
    mountpoint   = "/boot"
    name         = "boot"
    size         = "256M"
    type         = "c"
  }

  image_partitions {
    name         = "root"
    type         = "83"
    start_sector = "532480"
    filesystem   = "ext4"
    size         = "0"
    mountpoint   = "/"
  }


  image_chroot_env             = ["PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"]
  qemu_binary_source_path      = "/usr/bin/qemu-aarch64-static"
  qemu_binary_destination_path = "/usr/bin/qemu-aarch64-static"

}


locals {
  formatted_timestamp = formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())
}

##-------------------------------------------
## SET VARIABLES
##-------------------------------------------

# Pi user password
variable "admin_password" {
  type = string
}

# Output Image Name
variable "image_name" {
  type = string
}

# Timezone Info
variable "timezone" {
  type = string
}

# Locale Info
variable "locale" {
  type = string
}

# Keyboard Layout 
variable "keyboard_layout" {
  type = string
}

# Apt Packages 
variable "packages" {
  type = list(string)
}

locals {
  apt_packages = join(" ", var.packages)
}

# Prompt Color Setting
variable "termcolor" {
  type = string
}

build {
  sources = ["source.arm.raspbian"]

##-------------------------------------------
## Begin initial setup script: 1_pre.sh
##-------------------------------------------
  provisioner "shell" {
    script = "./provision_scripts/1_pre.sh"
    environment_vars = [
        "ADMIN_PASSWORD=${var.admin_password}",
	      "APT_PACKAGES=${local.apt_packages}"
    ]
  }

##-------------------------------------------
## Set up binaries
##-------------------------------------------
  provisioner "file" {
    source      = "./bin/dhclient"
    destination = "/opt/xbin/dhclient"
  }
  provisioner "shell" {
    inline = [
      "chmod 755 /opt/xbin/dhclient"
    ]
  }

  provisioner "file" {
    source      = "./bin/dhclient-script-nogw"
    destination = "/sbin/dhclient-script-nogw"
  }
  provisioner "shell" {
    inline = [
      "chmod 744 /sbin/dhclient-script-nogw"
    ]
  }

##-------------------------------------------
## Set up configs
##-------------------------------------------
  provisioner "file" {
    source      = "./configs/50-rfkill-unblock.rules"
    destination = "/etc/udev/rules.d/50-rfkill-unblock.rules"
  }
  provisioner "shell" {
    inline = [
      "chmod 644 /etc/udev/rules.d/50-rfkill-unblock.rules"
    ]
  }

  provisioner "file" {
    source      = "./configs/bashrc"
    destination = "/home/user/.bashrc"
  }

  provisioner "shell" {
    inline = [
      "chmod 644 /home/user/.bashrc",
      "chown user:user /home/user/.bashrc"
    ]
  }

  provisioner "file" {
    source      = "./configs/bashrc"
    destination = "/root/.bashrc"
  }

  provisioner "shell" {
    inline = [
      "chmod 644 /root/.bashrc"
    ]
  }

  provisioner "file" {
    source      = "./configs/gpsd"
    destination = "/etc/default/gpsd"
  }
  provisioner "shell" {
    inline = [
      "chmod 664 /etc/default/gpsd"
    ]
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /etc/minicom",
      "chown -R root:root /etc/minicom"
    ]
  }

  provisioner "file" {
    source      = "./configs/minirc.dfl"
    destination = "/etc/minicom/minirc.dfl"
  }
  provisioner "shell" {
    inline = [
      "chmod 644 /etc/minicom/minirc.dfl"
    ]
  }

  provisioner "file" {
    source      = "./configs/ntp.conf"
    destination = "/etc/ntp.conf"
  }
  provisioner "shell" {
    inline = [
      "chmod 644 /etc/ntp.conf"
    ]
  }

  provisioner "file" {
    source      = "./configs/tmux.conf"
    destination = "/home/user/.tmux.conf"
  }
  provisioner "shell" {
    inline = [
      "chmod 644 /home/user/.tmux.conf",
      "chown user:user /home/user/.tmux.conf"
    ]
  }

  provisioner "file" {
    source      = "./configs/tmux.conf"
    destination = "/root/.tmux.conf"
  }
  provisioner "shell" {
    inline = [
      "chmod 644 /root/.tmux.conf"
    ]
  }

  provisioner "file" {
    source      = "./configs/wlan0.conf"
    destination = "/etc/wpa_supplicant/wlan0.conf"
  }
  provisioner "shell" {
    inline = [
      "chmod 644 /root/.tmux.conf"
    ]
  }

  provisioner "file" {
    source      = "./configs/dnsmasq.conf"
    destination = "/etc/dnsmasq.conf"
  }
  provisioner "shell" {
    inline = [
      "chmod 644 /etc/dnsmasq.conf"
    ]
  }

  provisioner "file" {
    source      = "./configs/hostapd.conf"
    destination = "/etc/hostapd/hostapd.conf"
  }
  provisioner "shell" {
    inline = [
      "chmod 644 /etc/hostapd/hostapd.conf"
    ]
  }

##-------------------------------------------
## Set up crypto
##-------------------------------------------
  provisioner "shell" {
    inline = [
      "mkdir -p /home/user/.ssh",
      "chown user:user /home/user/.ssh"
    ]
  }

  provisioner "file" {
    source      = "./crypto/authorized_keys"
    destination = "/home/user/.ssh/authorized_keys"
  }
  provisioner "shell" {
    inline = [
      "chmod 644 /home/user/.ssh/authorized_keys"
    ]
  }

##-------------------------------------------
## Set up scripts
##-------------------------------------------
  provisioner "file" {
    source      = "./scripts/eapol_check"
    destination = "/opt/xbin/eapol_check"
  }
  provisioner "shell" {
    inline = [
      "chmod 755 /opt/xbin/eapol_check"
    ]
  }

provisioner "file" {
    source      = "./scripts/monmode"
    destination = "/opt/xbin/monmode"
  }
  provisioner "shell" {
    inline = [
      "chmod 755 /opt/xbin/monmode"
    ]
  }

  provisioner "file" {
    source      = "./scripts/manmode"
    destination = "/opt/xbin/manmode"
  }
  provisioner "shell" {
    inline = [
      "chmod 755 /opt/xbin/manmode"
    ]
  }

  provisioner "file" {
    source      = "./scripts/set_hostname"
    destination = "/opt/xbin/set_hostname"
  }
  provisioner "shell" {
    inline = [
      "chmod 755 /opt/xbin/set_hostname"
    ]
  }

  provisioner "file" {
    source      = "./scripts/set_ttl"
    destination = "/opt/xbin/set_ttl"
  }
  provisioner "shell" {
    inline = [
      "chmod 755 /opt/xbin/set_ttl"
    ]
  }

  provisioner "file" {
    source      = "./scripts/tmount"
    destination = "/opt/xbin/tmount"
  }
  provisioner "shell" {
    inline = [
      "chmod 755 /opt/xbin/tmount"
    ]
  }

  provisioner "file" {
    source      = "./scripts/tumount"
    destination = "/opt/xbin/tumount"
  }
  provisioner "shell" {
    inline = [
      "chmod 755 /opt/xbin/tumount"
    ]
  }

  provisioner "file" {
    source      = "./scripts/start-AP.sh"
    destination = "/opt/xbin/start-AP.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod 755 /opt/xbin/start-AP.sh"
    ]
  }

  provisioner "file" {
    source      = "./scripts/stop-AP.sh"
    destination = "/opt/xbin/stop-AP.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod 755 /opt/xbin/stop-AP.sh"
    ]
  }

  provisioner "file" {
    source      = "./scripts/wifi-client.sh"
    destination = "/opt/xbin/wifi-client.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod 755 /opt/xbin/wifi-client.sh"
    ]
  }

  provisioner "file" {
    source      = "./crypto/wg0.conf"
    destination = "/etc/wireguard/wg0.conf"
  }
  provisioner "shell" {
    inline = [
      "chmod 755 /opt/xbin/wifi-client.sh"
    ]
  }

##-------------------------------------------
## Set up services
##-------------------------------------------
    provisioner "file" {
    source      = "./services/iw-reg.service"
    destination = "/etc/systemd/system/iw-reg.service"
  }
  provisioner "shell" {
    inline = [
      "chmod 644 /etc/systemd/system/iw-reg.service"
    ]
  }

  provisioner "file" {
    source      = "./configs/00-wifi-name.link.disabled"
    destination = "/etc/systemd/network/00-wifi-name.link.disabled"
  }
  provisioner "shell" {
    inline = [
      "chmod 644 /etc/systemd/network/00-wifi-name.link.disabled"
    ]
  }
  
  provisioner "file" {
    source      = "./configs/10-wifi.link"
    destination = "/etc/systemd/network/10-wifi.link"
  }
  provisioner "shell" {
    inline = [
      "chmod 644 /etc/systemd/network/10-wifi.link"
    ]
  }

  provisioner "file" {
    source      = "./configs/01-netplan.yaml"
    destination = "/etc/netplan/01-netplan.yaml"
  }
  provisioner "shell" {
    inline = [
      "chmod 600 /etc/netplan/01-netplan.yaml"
    ]
  }

  provisioner "file" {
    source      = "./services/startap.service"
    destination = "/etc/systemd/system/startap.service"
  }
  provisioner "shell" {
    inline = [
      "chmod 600 /etc/systemd/system/startap.service"
    ]
  }

  provisioner "file" {
    source      = "./configs/route-metrics"
    destination = "/etc/dhcp/dhclient-exit-hooks.d/route-metrics"
  }
  provisioner "shell" {
    inline = [
      "chmod 600 etc/dhcp/dhclient-exit-hooks.d/route-metrics"
    ]
  }

##-------------------------------------------
## Recursively copy the include_bin directory contents to /opt/xbin
##-------------------------------------------
  provisioner "file" {
    source      = "./bin/include_bin/"    
    destination = "/opt/xbin/"     
  }
  provisioner "shell" {
    inline = [
      "chmod +x /opt/xbin/*"
    ]
  }


##-------------------------------------------
## Begin secondary setup script: 2_post.sh
##-------------------------------------------
  provisioner "shell" {
    script = "./provision_scripts/2_post.sh"
    environment_vars = [
        "LOCALE=${var.locale}",
        "KEYBOARD_LAYOUT=${var.keyboard_layout}",
        "TIMEZONE=${var.timezone}",
        "TERMCOLOR=${var.termcolor}"
    ]
  }

  # File provisioner to download the log file created by provision-pi.sh during the build process
  provisioner "file" {
    source = "/opt/src/logs/provision-pi.log"
    destination = "provision-pi.log-${local.formatted_timestamp}"
    direction = "download"
  }

  # Remove the log file from the Raspberry Pi
  provisioner "shell" {
    inline = [
      "rm /opt/src/logs/provision-pi.log"
    ]
  }

##-------------------------------------------
## Begin final setup script: 3_cleanup.sh
##-------------------------------------------
  post-processor "shell-local" {
    inline = [
      "mkdir -p /build/logs",
      "sha256sum /build/${var.image_name} >> /build/logs/temp-image-sha256.sum",
      "mv /build/provision-pi.log-* /build/logs/",
      "LATEST_LOG=$(ls -Art /build/packer-build-*.log | tail -n 1)",
      "sh /build/provision_scripts/3_cleanup.sh \"$LATEST_LOG\"",
      "mv /build/packer-build-*.log /build/logs/"
    ]
  }
}



