#!/usr/bin/env bash

#
# Add to this script any task that you would like to be run
# in the venv environment prior any other sqdr-ssap automation.
#

apt update
apt install -y python3 dh-python python3-pip
python3 -m pip install --upgrade cython==0.29.32 setuptools==65.6.3 packaging==22.0