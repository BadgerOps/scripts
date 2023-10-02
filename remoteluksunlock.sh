#!/usr/bin/expect -f
#
# This script uses 'expect' to connect to a remote host and send a LUKS passphrase
# see https://blog.badgerops.net/using-dropbear-ssh-daemon-to-enable-remote-luks-unlocking/ for more details
 
if {[llength $argv] == 0} {
  send_user "Usage: $argv0 \hostname, port, passphrase\n"
  exit 64
}

set HOST [lindex $argv 0];
set PORT [lindex $argv 1];
set PASSPHRASE [lindex $argv 2];
 
spawn ssh -oStrictHostKeyChecking=no -oCheckHostIP=no -p ${PORT} root@${HOST}
expect "Enter passphrase: "
sleep 1
send "${PASSPHRASE}\r"
expect "# "
sleep 1
