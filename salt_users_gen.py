#!/usr/bin/python2.7

import os
import pwd
import yaml
import fnmatch

user_dir = '/home'
output_dir = '/tmp'

class YamlUsergen(object):
    """
    This program is designed to examine the /home directory for users, grab their ssh keys from authorized_keys
    and their uid from the /etc/passwd file, and output a yaml file that works with Saltstack users formula:
    https://github.com/saltstack-formulas/users-formula

    This could be easily tweaked to support any other yaml based user management system, if needed
    """

    def __init__(self):
        """
        Set up initial items, right now just a list and couple dictionaries
        """
        self.users = []
        self.userkeys = {}
        self.combined = {}

    def get_users(self):
        """
        Generate a list of users based on who's got a /home folder. You can change this or modify
        this if you've got users that either have separate home folders or no home folders
        """

        print("getting list of users")
        users = os.listdir(user_dir)
        print("found {0} users".format(len(users)))
        return users

    def get_keys(self, users):
        """
        Create a dictionary of usernames, and their ssh key(s)
        """
        print("getting users keys")
        for user in users:
            keys = []
            try:
                for fn in os.listdir('{0}/{1}/.ssh'.format(user_dir, user)): # sometimes authorized_keys is authorized_keys2 /shrug
                    if fnmatch.fnmatch(fn, 'authorized_keys*'): # use fnmatch to fuzzy match authorized_keys*
                        with open('{0}/{1}/.ssh/{2}'.format(user_dir, user, fn), 'r') as fh: # use that matched file (fn) to open and extract keys
                            for line in fh.readlines():
                                keys.append(line)
                            self.userkeys[user] = keys
            except Exception as e:
                print("Couldn't find keys for {0}/{1}/.ssh/authorized_keys, error: {2}".format(root_dir, user, e))

    def get_uids(self, users):
        """Grab UID's and Full names from /etc/passwd and create a dictionary
        where the username is the key, and the uid, fullname and ssh_auth_file(s)
        are a dictionary within the key"""
        print("getting UID's and Full names for {0} users".format(len(users)))
        for user in users:
            try:
                pw = pwd.getpwnam(user) # use the pwd built-in to get the /etc/passwd file info (username, gid, fullname)
                combined[user] = { # key is the username
                'uid': pw.pw_uid,
                'fullname': pw.pw_gecos.split(',')[0], # pw_gecos gives us fullname but also some further info. This breaks yaml, so we split on , and select the 0'th value
                'ssh_auth_file': self.userkeys[user]
                }
            except Exception as e:
                print("couldn't set UID/fullname for {0} error: {1}".format(user, e))
                pass
        print("Done! Set {0} users/uids/keys".format(len(combined)))
        return combined

    def write_file(self, combined):
        """
        Now that we've generated our dictionary of users/users info, lets write a yaml
        file with all that info, which should plug straight into salt, or ansible user generation.
        """
        with open(output_dir + '/users.yml','w') as fw:
            yaml.dump(combined, fw, explicit_start=True, default_flow_style=False)

    def run(self):
        """
        Run each function in sequence, theoretically we could use these independant of each other,
        even though we probably never will.
        """
        self.users = self.get_users()
        self.get_keys(self.users)
        self.combined = self.get_uids(self.users)
        self.write_file(self.combined)

if __name__ == '__main__':
    """
    If we're running this interactively, just run()
    """
    YU = YamlUsergen()
    YU.run()
