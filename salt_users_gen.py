#!/usr/bin/python2.7

import os
import pwd
import yaml
import fnmatch

root_dir = '/home'
output_dir = '/tmp'

class YamlUsergen(object):
    """
    This program is designed to examine the /home directory for users, grab their ssh keys from authorized_keys
    and their uid from the /etc/passwd file, and output a yaml file that works with Saltstack users formula:
    https://github.com/saltstack-formulas/users-formula

    This could be easily tweaked to support any other yaml based user management system, if needed
    """

    def __init__(self):
        self.users = []
        self.userkeys = {}
        self.combined = {}

    def get_users(self):
        home_dir = '/home'
        print("getting list of users")
        users = os.listdir(home_dir)
        print("There are {} users in /home, they are: \n".format(len(users)))
        for user in users:
            print(user)
        res = raw_input("Do these all look like valid users?  Y/N \n") # if running in python 3.6 change this to input() not raw_input()
        if 'y' in res.lower():
            self.users = users
        else:
            print("ok, bailing out - remove invalid users from /home and try again \n")
            exit(1)

    def get_keys(self):
        print("getting users keys")
        for user in self.users:
            keys = []
            try:
                for fn in os.listdir('{}/{}/.ssh'.format(root_dir, user)):
                    if fnmatch.fnmatch(fn, 'authorized_keys*'):
                        with open('{}/{}/.ssh/{}'.format(root_dir, user, fn), 'r') as fh:
                            for line in fh.readlines():
                                keys.append(line)
                            self.userkeys[user] = keys
            except Exception as e:
                print("Couldn't find keys for {}/{}/.ssh/authorized_keys, error: {}".format(root_dir, user, e))

    def get_uids(self):
        """Grab UID's and Full names from /etc/passwd"""
        print("getting UID's and Full names for {} users".format(len(self.users)))
        for user in self.users:
            try:
                pw = pwd.getpwnam(user)
                self.combined[user] = {'uid': pw.pw_uid, 'fullname': pw.pw_gecos, 'ssh_auth_file': self.userkeys[user] }
            except Exception as e:
                print('couldn\'t set UID/fullname for {} error: {}'.format(user, e))
                pass
        print("Done! Set {} users/uids/keys".format(len(self.combined)))

    def write_file(self):
        with open(output_dir + '/users.yml','w') as fw:
            yaml.dump(self.combined, fw, explicit_start=True, default_flow_style=False)


    def run(self):
        self.get_users()
        self.get_keys()
        self.get_uids()
        self.write_file()

if __name__ == '__main__':
    YU = YamlUsergen()
    YU.run()