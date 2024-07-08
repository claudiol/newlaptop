#!/bin/bash
###############################################################################
# CACI RHEL 7.9 DVD CREATOR
#
# This script is based on the work by Frank Caviggia, Red Hat Consulting
# 
# This script is NOT SUPPORTED by Red Hat Global Support Services.
#
# Author: Lester Claudio (claudiol@redhat.com)
# Copyright: Red Hat, (c) 2014
# Version: 0.1 
# License: Apache License, Version 2.0
# Description: Kickstart Installation of RHEL 7 with Updated Intel e1000e(Ver 11) NIC Driver
###############################################################################

# GLOBAL VARIABLES
DIR=`pwd`

# USAGE STATEMENT
function usage() {
cat << EOF
usage: $0 rhel-server-7.X-x86_64-dvd.iso

Intel NIC RHEL Kickstart RHEL 7.9

Customizes a RHEL 7.9 x86_64 Server or Workstation DVD to install
with the following :

  - New updated (e1000e) Intel NIC Kernel Module downloaded from:
https://managedway.dl.sourceforge.net/project/e1000/e1000e%20stable/3.8.7/e1000e-3.8.7.tar.gz

EOF
}

function checkCLArguments() {
   echo -n "Checking arguments ..."
   if [ "$1." = "." ]; then
      usage
      exit 1
   fi

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
   echo "done."
}

function checkRoot () {
  echo -n "Checking for root ..."
  # Check for root user
  if [[ $EUID -ne 0 ]]; then
	if [ -z "$QUIET" ]; then
		echo
		tput setaf 1;echo -e "\033[1mPlease re-run this script as root!\033[0m";tput sgr0
	fi
	exit 1
  fi
  echo "done."
}

function checkPreRequisites () {
  echo -n "Checking for prereqs ..."
  # Check for required packages
  rpm -q genisoimage &> /dev/null
  if [ $? -ne 0 ]; then
	  yum install -y genisoimage
  fi

  rpm -q syslinux &> /dev/null
  if [ $? -ne 0 ]; then
	yum install -y syslinux 
  fi

  rpm -q isomd5sum &> /dev/null
  if [ $? -ne 0 ]; then
	  yum install -y isomd5sum
  fi
  echo "done."
}

function checkBootableDvd () {  
  echo -n "Checking bootable dvd distro ..."
  # Determine if DVD is Bootable
  `file $1 | grep -q -e "9660.*boot" -e "x86 boot" -e "DOS/MBR boot"`
  if [[ $? -eq 0 ]]; then
	echo "Mounting RHEL DVD Image..."
	mkdir -p /rhel
	mkdir -p $DIR/rhel-dvd
	mount -o loop $1 /rhel
	echo "Done."
	# Tests DVD for RHEL 7.9
	if [ -e /rhel/.discinfo ]; then
		RHEL_VERSION=$(grep "Red Hat" /rhel/.discinfo | awk -F ' ' '{ print $5 }')
		MAJOR=$(echo $RHEL_VERSION | awk -F '.' '{ print $1 }')
		MINOR=$(echo $RHEL_VERSION | awk -F '.' -F ' ' '{ print $2 }')
		if [[ $MAJOR -ne 7 ]]; then
			echo "ERROR: Image is not RHEL 7.4+"
			umount /rhel
			rm -rf /rhel
			exit 1
		fi
		if [[ $MINOR -ge 9 ]]; then
			echo "ERROR: Image is not RHEL 7.9"
			umount /rhel
			rm -rf /rhel
			exit 1
		fi
	else
		echo "ERROR: Image is not RHEL"
		exit 1
	fi

	echo -n "Copying RHEL DVD Image..."
	cp -a /rhel/* $DIR/rhel-dvd/
	cp -a /rhel/.discinfo $DIR/rhel-dvd/
        cp /root/rpmbuild/RPMS/x86_64/e1000e-3.8.4-1.x86_64.rpm $DIR/rhel-dvd/Packages/

        cd $DIR/rhel-dvd/Packages
        #####createrepo Packages
        createrepo --update -g /root/driver/rhel-dvd/repodata/3df90817a193baef023d53222cc4ce8f4d15209e593bee361bf72016022008fb-comps-Server.x86_64.xml ..
	echo " Done."
	umount /rhel
	rm -rf /rhel
  else
	echo "ERROR: ISO image is not bootable."
	exit 1
  fi
  echo "done."
}

nicversion=e1000e-3.8.4
function compileIntelDriver () {
  echo -n "Compiling new driver for e1000e..."
  if [ ! -d ./$nicversion/src ]; then
    echo "Download https://downloadmirror.intel.com/15817/eng/e1000e-3.8.4.tar.gz first and extract it to `pwd` directory."
    exit 1
  fi
  cd $nicversion/src
  make clean 2>&1
  make > nic-make.log 2>&1 
  /usr/src/kernels/3.10.0-1160.el7.x86_64/scripts/sign-file -v sha256 /root/driver/key/my_signing_key.priv /root/driver/key/my_signing_key_pub.der e1000e.ko
  cd /root/driver
  echo "Done."

  echo -n "Compressing kernel module to RHEL ISO ..."
  #xz -9 /root/driver/newdriver/lib/modules/3.10.0-1127.19.1.el7.x86_64/extra/e1000e/e1000e.ko
  xz -9 ./$nicversion/src/e1000e.ko
  echo "Done."
}

function mountIsolinuxInitrd () {
  echo -n "Mounting isolinux/initrd.img kernel module to RHEL ISO ..."
  cd /root/driver
  mkdir -p isolinux-initrd
  cd isolinux-initrd
  cp ../rhel-dvd/isolinux/initrd.img .
  unxz -S .img initrd.img 
  cat initrd | cpio -idm
  rm -f initrd
  cd /root/driver
  rm -f isolinux-initrd/usr/lib/modules/3.10.0-1160.el7.x86_64/kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko.xz
  cp -f ./$nicversion/src/e1000e.ko.xz isolinux-initrd/usr/lib/modules/3.10.0-1160.el7.x86_64/kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko.xz
  mkdir -p isolinux-initrd/etc/modules-load.d
  cp -f /root/driver/config/nicupdate/e1000e.conf isolinux-initrd/etc/modules-load.d
  
  echo "done."
  echo -n "Compressing isolinux initrd.img file using LZMA format..."
  cd isolinux-initrd
  find . 2>/dev/null | cpio -c -o > ../initrd
  cd /root/driver
  xz -S .img --format=lzma initrd 
  echo "done."
  echo "Done."
}

function modIsolinuxInitrd () { 
  echo -n "Modifying RHEL DVD isolinux/initrd.img file ..."
  cd /root/driver
  rm -f rhel-dvd/isolinux/initrd.img
  cp -f initrd.img rhel-dvd/isolinux/
  rm -f initrd.img
  rm -rf isolinux-initrd
  echo "done."
}

function mountPxebootInitrd () {
  echo -n "Mounting images/pxeboot/initrd.img kernel module to RHEL ISO ..."
  cd /root/driver
  mkdir -p pxeboot-initrd
  cd pxeboot-initrd
  cp ../rhel-dvd/images/pxeboot/initrd.img .
  unxz -S .img initrd.img 
  cat initrd | cpio -idm
  rm -f initrd
  cd /root/driver
  rm -f pxeboot-initrd/usr/lib/modules/3.10.0-1160.el7.x86_64/kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko.xz
  cp -f ./$nicversion/src/e1000e.ko.xz pxeboot-initrd/usr/lib/modules/3.10.0-1160.el7.x86_64/kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko.xz
  mkdir -p pxeboot-initrd/etc/modules-load.d
  cp -f /root/driver/config/nicupdate/e1000e.conf pxeboot-initrd/etc/modules-load.d
  echo -n "Signing all pxeboot initrd.img files ..."
  cd pxeboot-initrd
  echo -n "Compressing pxeboot initrd.img file using LZMA format..."
  find . 2>/dev/null | cpio -c -o > ../initrd;cd ..;xz -S .img --format=lzma initrd 
  cd /root/driver
  echo "done."
}

function modPxebootInitrd () {
  echo -n "Modifying RHEL DVD images/pxeboot/initrd.img file ..."
  cd /root/driver
  rm -f rhel-dvd/images/pxeboot/initrd.img
  cp -f initrd.img rhel-dvd/images/pxeboot/initrd.img
  rm -f initrd.img
  rm -rf pxeboot-initrd
  echo "done."
}

function mountIsolinuxUpgradeImage () {
  echo -n "Mounting isolinux/upgrade.img kernel module to RHEL ISO ..."
  cd /root/driver
  mkdir -p isolinux-upgrade
  cd isolinux-upgrade
  cp ../rhel-dvd/isolinux/upgrade.img .
  unxz -S .img upgrade.img 
  cat upgrade | cpio -idm
  rm -f upgrade
  cd /root/driver
  rm -f isolinux-upgrade/usr/lib/modules/3.10.0-1160.el7.x86_64/kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko.xz
  cp -f ./$nicversion/src/e1000e.ko.xz isolinux-upgrade/usr/lib/modules/3.10.0-1160.el7.x86_64/kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko.xz
  mkdir -p isolinux-upgrade/etc/modules-load.d
  cp -f /root/driver/config/nicupdate/e1000e.conf isolinux-upgrade/etc/modules-load.d
  echo "done."
  echo -n "Compressing isolinux upgrade.img file using LZMA format..."
  cd isolinux-upgrade
  find . 2>/dev/null | cpio -c -o > ../upgrade
  cd /root/driver
  xz -S .img --format=lzma upgrade
  echo "done."
  echo "Done."
}

function modIsolinuxUpgradeImage () { 
  echo -n "Modifying RHEL DVD isolinux/upgrade.img file ..."
  cd /root/driver
  rm -f rhel-dvd/isolinux/upgrade.img
  cp -f upgrade.img rhel-dvd/isolinux/
  rm -f upgrade.img
  rm -rf isolinux-upgrade
  echo "done."
}

function mountPxebootUpgradeImage () {
  echo -n "Mounting images/pxeboot/upgrade.img kernel module to RHEL ISO ..."
  cd /root/driver
  mkdir -p pxeboot-upgrade
  cd pxeboot-upgrade
  cp ../rhel-dvd/images/pxeboot/upgrade.img .
  unxz -S .img upgrade.img 
  cat upgrade | cpio -idm
  rm -f upgrade
  cd /root/driver
  rm -f pxeboot-upgrade/usr/lib/modules/3.10.0-1160.el7.x86_64/kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko.xz
  cp -f ./$nicversion/src/e1000e.ko.xz pxeboot-upgrade/usr/lib/modules/3.10.0-1160.el7.x86_64/kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko.xz
  mkdir -p pxeboot-upgrade/etc/modules-load.d
  cp -f /root/driver/config/nicupdate/e1000e.conf pxeboot-upgrade/etc/modules-load.d
  cd pxeboot-upgrade
  echo -n "Compressing pxeboot initrd.img file using LZMA format..."
  find . 2>/dev/null | cpio -c -o > ../upgrade;cd ..;xz -S .img --format=lzma upgrade
  cd /root/driver
  echo "done."
}

function modPxebootUpgradeImage () {
  echo -n "Modifying RHEL DVD images/pxeboot/upgrade.img file ..."
  cd /root/driver
  rm -f rhel-dvd/images/pxeboot/upgrade.img
  cp -f upgrade.img rhel-dvd/images/pxeboot/upgrade.img
  rm -f upgrade.img
  rm -rf pxeboot-upgrade
  echo "done."
}


function mountSquashFsImage () {
  echo -n "Mounting LiveOS/squashfs filesystem ..."
  cd /root/driver
  unsquashfs /root/driver/rhel-dvd/LiveOS/squashfs.img 
  cd /root/driver
  echo done
  #echo "mountSquashFsImage"
  #read ans
}
  
function mountRootFsImage () {
  echo -n "Mounting rootfs filesystem ..."
  mkdir -p /mnt/rootfs
  cd /root/driver
  mount /root/driver/squashfs-root/LiveOS/rootfs.img /mnt/rootfs
  echo "done."
  echo "mountRootFsImage"
  read ans
}

function copyNewKernelModule () {
  echo -n "Copying new nic kernel module ..."
  cp -f /root/driver/$nicversion/src/e1000e.ko.xz /mnt/rootfs/usr/lib/modules/3.10.0-1160.el7.x86_64/kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko.xz
  mkdir -p /mnt/rootfs/etc/modules-load.d
  cp -f /root/driver/config/nicupdate/e1000e.conf /mnt/rootfs/etc/modules-load.d
  echo "Done"
  echo "copyNewKernelModule"
  ls -lh /mnt/rootfs/usr/lib/modules/3.10.0-1160.el7.x86_64/kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko.xz
  ls -lh /mnt/rootfs/etc/modprobe.d
  read ans
  umount /mnt/rootfs
}

function rebuildSquashFsImage () {
  echo -n "Reconstructing squashfs.img ..."
  cd /root/driver
  mksquashfs /root/driver/squashfs-root/ /root/driver/squashfs.img -noappend -always-use-fragments
  cp squashfs.img rhel-dvd/LiveOS/
  rm -f squashfs.img
  rm -rf squashfs-root
  echo "done"
  #echo "rebuildSquashFsImage"
  #read ans
}

function remasterRHELDvd () {
  echo "Remastering RHEL DVD Image..."
  cd $DIR/rhel-dvd
  chmod u+w isolinux/isolinux.bin
  find . -name TRANS.TBL -exec rm '{}' \; 
  /usr/bin/mkisofs -J -T -V "RHEL-$RHEL_VERSION Server.x86_64" -o $DIR/rhel-$RHEL_VERSION-nic.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -R -m TRANS.TBL .
  cd $DIR
  rm -rf $DIR/rhel-dvd
  echo "Done."
}

function signRhelDvdImage () {
  echo "Signing RHEL DVD Image..."
  /usr/bin/isohybrid --uefi $DIR/rhel-$RHEL_VERSION-nic.iso &> /dev/null
  /usr/bin/implantisomd5 $DIR/rhel-$RHEL_VERSION-nic.iso
  echo "Done."
}

checkCLArguments $*
checkRoot 
checkPreRequisites
compileIntelDriver
checkBootableDvd $1
mountIsolinuxInitrd
modIsolinuxInitrd 
mountIsolinuxUpgradeImage
modIsolinuxUpgradeImage
mountPxebootInitrd 
modPxebootInitrd 
mountPxebootUpgradeImage
modPxebootUpgradeImage
mountSquashFsImage 
mountRootFsImage 
copyNewKernelModule 
rebuildSquashFsImage 
remasterRHELDvd
signRhelDvdImage

echo "DVD Created. [rhel-$RHEL_VERSION-nic.iso]"

exit 0
