#!/usr/bin/env python

import requests
import logging
import argparse
from fabric.api import env, run, settings
from fabric.colors import blue, green, red, yellow
import yact
import sys
import re


class ServerDeploy(object):

    def __init__(self):
        self.cfg = {}
        self.setupcfg()
        self.setup_logging()
        self.args = None
        self.setup_argparse()

    def setup_argparse(self):
        parser = argparse.ArgumentParser(description='command line flags for interacting with servers in Singlehop '
                                                     'The available options are below, note that you can also create '
                                                     'a configuration file with the singlehop username/password/url'
                                                     'so you dont have to pass them in here',
                                         epilog='you can hit https://<atlassian_URL> for more info') #TODO: enter url
        parser.add_argument('--shuser', help='singlehop username', required=False)
        parser.add_argument('--shpass', help='singlehop password', required=False)
        parser.add_argument('--list-servers', help='list servers in singlehop account', action='store_true',
                            required=False)
        parser.add_argument('--update-server-list', action='store_true',
                            help='creates a yaml file in currdir with a list of servers in singlehop', required=False)
        parser.add_argument('--get-server-password', help='get the singlehop root password for a server. requires -pin '
                                                          'and -serverid', action='store_true', required=False)
        parser.add_argument('--get-server-ip', help='get the public IP for this server - requires '
                                                    '-serverid', action='store_true', required=False)
        parser.add_argument('-pin', help='singlehop account pin', action='store', required=False)
        parser.add_argument('-serverid', help='singlehop serverid', action='store', required=False)

        self.args = parser.parse_args()
        if len(sys.argv) <= 1:
            parser.print_help()

    def setupcfg(self):
        self.cfg = yact.from_file('config.yaml')

    def setup_logging(self):
        """
        set up logging
        :return:
        """
        facilityname = "deploy-app"
        log = logging.getLogger(facilityname)
        log.setLevel('INFO')
        handler = logging.basicConfig(level=logging.DEBUG,
                                      format='%(asctime)s [%(levelname)s] %(message)-20s',
                                      datefmt='%Y-%m-%d %H:%M:%S')
        logging.StreamHandler(sys.stdout)
        log.addHandler(handler)

        logging.info(blue("Initializing Application"))

    def leap3api(self, method=None, endpoint=None, data=None):
        """
        The purpose of this is to interact with leap3 API endpoint
        You have to pass in the relevant endpoint, and, optionally if its
        a post vs get
        :param method: what method is used? GET or POST
        :param endpoint: what endpoint is hit? http://dropzonewiki.singlehop.com/index.php?title=Server
        :param data: what data is sent? For example, the POST to get the server root password requires a pin to be sent
        :return: json data from the leap3 api endpoint
        """
        if method == 'get':
            try:
                output = requests.get(self.cfg['sh']['url'] + endpoint, auth=(self.cfg['sh']['username'],
                                                                                     self.cfg['sh']['password']))
                if output.status_code == 200:
                    return output.json()['data']
                else:
                    print('unable to get data from URL err: {} {}'.format(output.status_code, output.text))
            except Exception as e:
                print('exception getting data from singlehop: {}'.format(e, exc_info=1))
        elif method == 'post':
            try:
                output = requests.post(self.cfg['sh']['url'] + endpoint, data=data,
                                       auth=(self.cfg['sh']['username'], self.cfg['sh']['password']))
                if output.status_code == 200:
                    return output.json()['data']
                else:
                    print('unable to get data from URL err: {} {}'.format(output.status_code, output.text))
            except Exception as e:
                print('exception posting data to singlehop: {}'.format(e, exc_info=1))
        else:
            print("must specify a method")

    def updateserverlist(self):

        serverlist = yact.from_file('serverlist.yaml')
        raw = self.leap3api(method='get', endpoint='/server/list')
        for k, v in raw.items():
            serverlist.set(k, v)
        print('updated serverlist.yaml to latest data from singlehop')

    def listservers(self):
        hosts = {}
        raw = self.leap3api(method='get', endpoint='/server/list')
        for k, v in raw.items():
            hosts[v['hostname']] = k
        print(green("below are the servers and singlehop server id's: \n"))
        for host in sorted(hosts):
            # the :<25 here pads the printout so it looks better on screen
            print("{0:<25} - serverid: {1}".format(host, hosts[host]))

    def getserverdisks(self, server=None, ssh_password=None):
        disks = {}
        if server:
            if ssh_password:
                pass
            else:
                ssh_password = self.getserverpassword(serverid=server, pin=self.cfg['sh']['pin'])
                hostip = self.getserverip(serverid=server)
                with settings(host_string=hostip, user="root", password=ssh_password):
                    output = run('lsblk -n -d -r -io KNAME,TYPE,ROTA,SIZE,MODEL')
                for line in output.splitlines():
                    r = re.match('(?P<disk>sd[a-z]) (?P<type>disk) (?P<rotation>\d) (?P<size>\d+.\d\w) (?P<model>\w[0-9a-zA-Z -]+)', line)
                    disks[r.group('disk')] = r.groupdict()
        return disks

    def getserverip(self, serverid=None):
        raw = self.leap3api(method='get', endpoint='/server/view/{}'.format(serverid))
        ip = raw['primaryip']
        return ip

    def getserverpassword(self, serverid=None, pin=None):
        if serverid:
            if pin:
                sh_pin = {'pin': pin}
                return self.leap3api(method='post', endpoint='/server/getpassword/{id}'.format(id=serverid), data=sh_pin)
        else:
            print("you have to set serverid to use this!")

    def formatdisks(self, serverid=None):
        pass

    def main(self):
        if self.args.list_servers:
            self.listservers()
        if self.args.get_server_password:
            password = self.getserverpassword(serverid=self.args.serverid, pin=self.args.pin)
            print(green("password for this server is: {}".format(password)))
        if self.args.get_server_ip:
            print(green('server public IP is: {}'.format(self.getserverip(serverid=self.args.serverid))))


if __name__ == '__main__':
    sd = ServerDeploy()
    sd.main()
