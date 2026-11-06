## Provision Scripts
This directory contains the Bash scripts that run on the provisioning image. They work in a pre-defined order to allow for segmented processing of tasks before and after packer copies files into the Pi image.

### 1_pre.sh
This script is run on the image prior to the Packer provisioner sending files over. This is useful for pre-setup and configuration before you transfer configuration files and binaries. This should be kept as short and clean as possible.


### 2_post.sh
This script runs after files are transferred into the image by the Packer provisioner. The majority of your changes should occur in this file, particularly if they rely on a file that you have to copy over first. 

### 3_cleanup.sh
This final script occurs post provisioning and is used to clean up logs and artifacts. 