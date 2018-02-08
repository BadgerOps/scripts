#!/usr/bin/expect -f
 
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
