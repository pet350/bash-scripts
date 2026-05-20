#!/bin/bash
# Script To Setup OpenXenManager

apt install git python-gtk2 glade python-gtk-vnc python-glade2 python-configobj python-setuptools -y
cd /usr/local/lib
git clone https://github.com/OpenXenManager/openxenmanager.git
cd openxenmanager
python setup.py install
## All Done!

