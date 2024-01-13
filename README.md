# Scripts


Just a collection of random scripts I've written over time. Storing here for portability, and sharing, if they end up being useful for others.

#### What they do


The [salt_users_gen.py](./salt_users_gen.py) file will create a SaltStack Pillar file for all users on a given system, including their ssh id_rsa.pub keys, read in from the `~/.ssh/authorized_keys` file. This was a very quick way of converting user management from manual to automated on a ~150 user system.


The [remoteluksunlock.sh](./remoteluksunlock.sh) and [checkport](./checkport) scripts are used together to enable remote unlocking of FDE Luks encrypted machines. See https://blog.badgerops.net/using-dropbear-ssh-daemon-to-enable-remote-luks-unlocking/ for more details.


The [racadm-disk-mounting](./racadm-disk-mounting.sh) is a quick wrapper to make mounting/unmounting iso files to a Dell physical host easier. It is portable, only needs the racadm program installed.

# For a single host
```bash
./racadm_script.sh -h <HOST_IP_OR_HOSTNAME> -u <USERNAME> -p <PASSWORD> [--debug]
```

# For multiple hosts from a newline separated text file
```bash
./racadm_script.sh -i hosts.txt -u <USERNAME> -p <PASSWORD> [--debug] [--restart-hosts]
```

#### Note:

The `singlehop-deployer` script [has moved here](https://github.com/BadgerOps/singlehop-deployer) for posterity. I think Single Hop got bought out and their API got nuked.