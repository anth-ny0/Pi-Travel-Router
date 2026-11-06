#!/bin/bash
# Make sure we have crypto files
mkdir -p crypto
mkdir -p bin/include_bin
touch crypto/authorized_keys

# Start the build
sudo docker run --rm -it --privileged --network=host -v /dev:/dev -v ${PWD}:/build -e PACKER_LOG_PATH="packer-build-$(date +%Y-%m-%d_%H-%M-%S).log" mkaczanowski/packer-builder-arm:latest build -var-file=config.pkrvars.hcl raspbian.pkr.hcl

