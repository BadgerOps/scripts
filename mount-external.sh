#!/usr/bin/bash

# set the target mountpoint for the external device (optional argv[1] override)

MOUNTPOINT=/mnt
MOUNTPOINT="${1:-$MOUNTPOINT}"

# if no argument was provided, print a short help message
if [ -z "${1:-}" ]; then
  cat << 'EOF'
about: mounts the first detected external usb storage device to a mountpoint
usage: ./mount-external.sh [mountpoint]
mountpoint: optional; if omitted, the script uses /mnt
notes: requires root privileges and exits if something is already mounted at the mountpoint
EOF
fi

# ensure the script is executed with root privileges

if [ "$(id -u)" != "0" ]; then
   echo "this script must be run as root" 1>&2
   exit 1
fi

echo "checking to see if an external disk is already mounted..."
# bail out early if something is already mounted at the mountpoint
if findmnt ${MOUNTPOINT}; then
  echo "looks like a disk is already mounted at ${MOUNTPOINT}, bailing out!"
  exit 1
fi

echo "checking to see if usb_storage is configured..."
# verify usb_storage kernel module is present; load it if missing
if lsmod | grep -wq usb_storage
then
  echo "usb_storage is already loaded!"
else
  echo "loading usb_storage module"
  modprobe --ignore-install usb-storage
fi

echo "checking to see if uas is configured..."
# verify uas kernel module is present; load it if missing
if lsmod | grep -wq uas
then
  echo "uas is already loaded!"
else
  echo "loading uas module"
  modprobe uas
fi

# scan available block devices for the first one identified as usb-backed
# look for the first matching device (id_bus=usb) and then break
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
# pick the first partition associated with the detected device
DEVPART=$(lsblk -p ${DEVPATH} -l -o name,type | grep part | awk '{print $1}')
# mount the selected partition at the configured mountpoint
echo "mounting ${DEVPART}"
mount ${DEVPART} ${MOUNTPOINT}
