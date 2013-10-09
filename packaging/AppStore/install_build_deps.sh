#!/bin/bash

if [ ! "$(whoami)" = "root" ] ; then
	echo "This script must be run as root."
	exit 1
fi

echo "Installing ubuntu system packages"
apt-get update
# Note, might need libxml2-dev, not libxml3-dev
apt-get install -y swig libxml3-dev libxslt1-dev build-essential libjpeg8 libjpeg-dev libfreetype6 libfreetype6-dev zlib1g-dev python-pip devscripts
apt-get build-dep -y python-numpy


# Fix ubuntu issue with PIL, should not be needed for Pillow
# ln -s /usr/lib/`uname -i`-linux-gnu/libfreetype.so /usr/lib/
# ln -s /usr/lib/`uname -i`-linux-gnu/libjpeg.so /usr/lib/
# ln -s /usr/lib/`uname -i`-linux-gnu/libz.so /usr/lib/

echo "Install systemwide pip packages"
# Must use virtualenv version 1.9, 1.10 has bugs with some of our package versions and doesn't support distribute properly
pip install virtualenv==1.9
