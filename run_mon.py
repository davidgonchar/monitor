import os
import pipes
import subprocess

import sys

from fabric.operations import sudo

__author__ = 'david'
from fabric.api import run, put, hosts, env, settings

###env.hosts = ['localhost']
env.password = 'root12'
env.user = 'root'


def run_cmd(cmd):
    with settings(warn_only=True):
        res = run(cmd)
        print('Command result: %s' % str(res))
        return res


def run_script(script_name, remote_dir='~/temp'):
    with settings(warn_only=True):
        cmd = 'mkdir -p {0}'.format(remote_dir)
        res = run(cmd)
        # print('Trying to prepare remote folder: %s' % str(res))

        put(script_name, remote_dir)

        fn = os.path.basename(script_name)
        cmd = 'chmod 777 {0}/{1} && cd {0} && ./{1}'.format(remote_dir, fn)
        res = run(cmd)
        print('Command result: %s' % str(res))
        return res


def run_db_cmd(cmd):
    with settings(warn_only=True):
        sudo_cmd = "su - postgres -c {0}".format(pipes.quote(cmd))
        res = sudo(sudo_cmd)
        print('Command result: %s' % str(res))
        return res


if __name__ == '__main__':

    try:
        if len(sys.argv) > 1:
            #
            #  If we got an argument then invoke fabric with it.
            #
            result = subprocess.call(['fab', '-f', __file__] + sys.argv[1:])
            print('Run result: %s' % result)
        else:
            #
            #  Otherwise list our targets.
            #
            subprocess.call(['fab', '-f', __file__, '--list'])
    except KeyboardInterrupt as e:
        print(e)
    print('Bye bye!..')

