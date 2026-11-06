## Bin Directory
This directory contains executable binaries to be copied to the image. All scripts are explicitly copied over with the exception of the `include_bin` explained below.

### include_bin
This directory is recursively copied into `/opt/xbin` and the contents are made executable. Use this for custom or proprietary binaries that may frequently change over time or between builds.
