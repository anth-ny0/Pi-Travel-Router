# Packer-Pi

## Overview
Packer-Pi is the baseline OTS Raspberry Pi image builder. It uses Packer to create customized Raspberry Pi OS images with standard tooling, configs, and services common to all OTS deployments. Feature-specific branches (e.g. `sixfab`, `bluetooth`) extend this baseline with connectivity and hardware support.

## Compatibility
This builder has been updated to Raspberry Pi OS Bookworm which has support for the Raspberry Pi 5 and all previous Pi versions. 

## Structure
This project has been refactored and split into numerous directories and files for readability. This new structure allows for easier customization of parts. You may add and remove elements as necessary and can easily customize variables within `config.pkrvars.hcl` to tweak your image characteristics such as installed packages, locale info, timezone info, and terminal prompt color.

## Build
To build an image, simply run the `build.sh` wrapper. This script hides the ugliness of Docker which is used for the backend Packer plugin and Pi emulation in qemu. 

```
./build.sh
```

### Build Errors
If you encounter an error saying the source code was not available, simply rerun the build. If it continues to fail, its likely a network connectivity issue.

### Caching
Packer will cache the base OS image after you download it the first time. This directory is `.packer_cache`. Its helpful to download this prior to deploying or going to a place with limited connectivity. If you need to transfer this project via thumb drive, you may have to delete the cache first.

## Files
### config.pkrvars.hcl
The config.pkrvars.hcl file contains all configurable packer variables to tweak the Pi image. Edit this file to change your output file name, terminal color, installed packages, the user password, and more.

### raspbian.pkr.hcl
The raspbian.pkr.hcl file is a HashiCorp Packer HCL template that defines how to build a customized Raspberry Pi OS (Raspbian) image. It declares the source image (where to download the base OS, checksum validation, decompression command, target size/type), the partition layout (e.g., boot and root partitions and their properties), and any build logic such as resizing the filesystem. It also includes build blocks that tie in provisioners—shell scripts, file copies, or other steps—to customize the image (install packages, configure services, apply tweaks) before exporting the final artifact. Variables (like the output image name) can be parameterized so the same template can be reused with different input.

This file is what copies things to and from our image and executes our provision scripts.
