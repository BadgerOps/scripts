# random_scripts


Just a collection of random scripts. Likely not useful for anything... 

You don't want these scripts. I wrote them to make my life easier and they'll probably do nothing to your box, OR
they'll bork your box. Good reference material maybe? Thats why I put them here. So I could reference them. Like a git-blog-post. <3

#### What they do


The [salt_users_gen.py](./salt_users_gen.py) file will create a SaltStack Pillar file for all users on a given system, including their ssh id_rsa.pub keys, read in from the `~/.ssh/authorized_keys` file. This was a very quick way of converting user management from manual to automated on a ~150 user system.


The [remoteluksunlock.sh](./remoteluksunlock.sh) and [checkport](./checkport) scripts are used together to enable remote unlocking of FDE Luks encrypted machines. See https://blog.badgerops.net/using-dropbear-ssh-daemon-to-enable-remote-luks-unlocking/ for more details.


#### Note:

The `singlehop-deployer` script [has moved here](https://github.com/BadgerOps/singlehop-deployer) for posterity. I think Single Hop got bought out and their API got nuked.