#!/usr/bin/bash

MOUNTPOINT=/mnt

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "checking to see if an external disk is already mounted..."
if findmnt ${MOUNTPOINT}; then
  echo "looks like a disk is already mounted at ${MOUNTPOINT}, bailing out!"
  exit 1
fi

echo "checking to see if usb_storage is configured..."
if lsmod | grep -wq usb_storage
then
  echo "usb_storage is already loaded!"
else
  echo "loading usb_storage module"
  modprobe --ignore-install usb-storage
fi

echo "checking to see if uas is configured..."
if lsmod | grep -wq uas
then
  echo "uas is already loaded!"
else
  echo "loading uas module"
  modprobe uas
fi

# look for the first matching device (ID_BUS=usb) and then break out of the loop and mount it
for device in /sys/block/sd*
do
  if udevadm info --query=property --path=${device} | grep -q ^ID_BUS=usb
  then
    DEVPATH=$(udevadm info --query=property --path=${device} | grep DEVNAME= | cut -d'=' -f2)
    echo "found external usb device at ${DEVPATH}"
    break
  fi
done

echo "finding partition on ${DEVPATH}"
DEVPART=$(lsblk -p ${DEVPATH} -l -o name,type | grep part | awk '{print $1}')
echo "Mounting ${DEVPART}"
mount ${DEVPART} ${MOUNTPOINT}
