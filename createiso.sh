#!/bin/sh
###############################################################################
# STIG FIX DVD CREATOR
#
# This script was written by Frank Caviggia, Red Hat Consulting
# Last update was 21 January 2014
# This script is NOT SUPPORTED by Red Hat Global Support Services.
# Please contact Josh Waldman for more information.
#
# Author: Frank Caviggia (fcaviggi@redhat.com)
# Copyright: Red Hat, (c) 2013
# Version: 1.1.3
# License: GPLv2
# Description: Kickstart Installation of RHEL 6 with DISA STIG 
###############################################################################

# GLOBAL VARIABLES
DIR=`pwd`

# USAGE STATEMENT
function usage() {
cat << EOF
usage: $0 rhel-server-6.5-x86_64-dvd.iso

DISA STIG Installer Kickstart RHEL 6.4+

Customizes a RHEL 6.4+ x86_64 Server or Workstation DVD to install
with the following hardening:

  - DISA STIG for Red Hat Enterprise Linux
  - DISA STIG for Firefox (User/Developer Workstation)
  - Classification Banner (Graphical Desktop)

EOF
}

while getopts ":vhq" OPTION; do
	case $OPTION in
		h)
			usage
			exit 0
			;;
		?)
			echo "ERROR: Invalid Option Provided!"
			echo
			usage
			exit 1
			;;
	esac
done

# Check for root user
if [[ $EUID -ne 0 ]]; then
	if [ -z "$QUIET" ]; then
		echo
		tput setaf 1;echo -e "\033[1mPlease re-run this script as root!\033[0m";tput sgr0
	fi
	exit 1
fi

# Determine if DVD is Bootable
`file $1 | grep 9660 | grep -q bootable`
if [[ $? -eq 0 ]]; then
	echo "Mounting RHEL DVD Image..."
	mkdir -p /rhel
	mkdir $DIR/rhel-dvd
	mount -o loop $1 /rhel
	echo "Done."
	# Tests DVD for RHEL 6.4+
	if [[ $(grep "Red Hat" /rhel/.discinfo | awk '{ print $5 }' | awk -F '.' '{ print $1 }') -ne 6 ]]; then
		echo "ERROR: Image is not RHEL 6.4+"
		umount /rhel
		rm -rf /rhel
		exit 1
	fi
	if [[ $(grep "Red Hat" /rhel/.discinfo | awk '{ print $5 }' | awk -F '.' '{ print $2 }') -lt 4 ]]; then
		echo "ERROR: Image is not RHEL 6.4+"
		umount /rhel
		rm -rf /rhel
		exit 1
	fi
	echo -n "Copying RHEL DVD Image..."
	cp -a /rhel/* $DIR/rhel-dvd/
	cp -a /rhel/.discinfo $DIR/rhel-dvd/
	echo " Done."
	umount /rhel
	rm -rf /rhel
else
	echo "ERROR: ISO image is not bootable."
	exit 1
fi

echo -n "Modifying RHEL DVD Image..."
cp -a $DIR/config/* $DIR/rhel-dvd/
echo " Done."

echo "Remastering RHEL DVD Image..."
cd $DIR/rhel-dvd
chmod u+w isolinux/isolinux.bin
find . -name TRANS.TBL -exec rm '{}' \; 
/usr/bin/mkisofs -J -T -o $DIR/rhel-stig-fix.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -m TRANS.TBL .
cd $DIR
rm -rf $DIR/rhel-dvd
echo "Done."

echo "Signing RHEL DVD Image..."
/usr/bin/implantisomd5 $DIR/rhel-stig-fix.iso
echo "Done."

echo "DVD Created. [rhel-stig-fix.iso]"

exit 0
