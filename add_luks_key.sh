#!/usr/bin/bash
#
# A script to add a new password/keyslot to a luks encrypted drive
# Using my standard bash script format
#

print_help(){
  echo "Usage: $0 [--old password] [--new  password] [--debug]"
}
set -e  # Exit on error

while [[ $# -gt 0 ]]; do
    case "$1" in
        --old)
            OLD="$2"
            shift 2
            ;;
        --new)
            NEW="$2"
            shift 2
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            print_help
            exit 1
            ;;
    esac
done

# check for debug mode, turn on set -x if so
if [ "$DEBUG" = true ]; then
    set -x
fi

# check to see if expect is installed 
if [[ ! -f /usr/bin/expect ]]; then
    echo "Expect is not installed, please install then retry"
    exit 1
fi

# now, read in the passwords if they weren't set above

if [ -z $OLD ]; then
  read -s -p "Enter old password: " OLD
fi

if [ -z $NEW ]; then
  read -s -p "Enter new password: " NEW
fi

set_new_password() {
    expect -c "
    set timeout 10
    spawn cryptsetup luksAddKey ${1} --force-password
    expect {
        \"Enter any existing passphrase:\" {
            send \"$2\r\"
            exp_continue
        }
        \"Enter new passphrase for key slot:\" {
            send \"$3\r\"
            exp_continue
        }
        \"Verify passphrase:\" {
            send \"$3\r\"
            exp_continue
        }
        eof
    }
    "
}

iterate_over_disks() {
    for DEVICE in $(lsblk -l -p -o name,fstype| awk '$2 ~ /^crypto_LUKS$/ { print $1}'); do
        echo "adding new luks password for ${DEVICE}"
        set_new_password ${DEVICE} ${OLD} ${NEW}
    done
}

main() {
    echo "Starting luks password add utility..."
    iterate_over_disks
}

main
