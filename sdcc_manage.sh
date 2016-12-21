#!/bin/bash

LOCAL_HOST=127.0.0.1
MONGODB_DIR_DEFAULT=/var/lib/mongo
MONGODB_DIR=/data/mongodb
MONGODB_LOG=/var/log/mongodb.log

if [ $# != 2 ]; then 
echo "Usage: $0 <remote host 1, e.g. 10.142.0.3> <remote host 2, e.g. 10.142.0.4>"
exit 1
fi

echo "=============== (`date`) Start script ==============="

REMOTE_HOST1=$1
REMOTE_HOST2=$2

# Start MongoDB server
function start_mongo()
{
echo "Starting MongoDB server (`date`)"
echo "MongoDB started (`date`)"
}

# Stop MongoDB server
function stop_mongo()
{
echo "Stopping MongoDB server (`date`)"
echo "MongoDB stopped (`date`)"
}

# Start SDCC services
function start_sdcc()
{
status=`systemctl status httpd | awk '/Active/{print $2}'`
echo "SDCC status: ${status}"
if [ "${status}" == "active" ]; then
    return
fi
echo "Starting SDCC services (`date`)"
sudo systemctl start httpd
echo "SDCC services started (`date`)"
}

# Stop SDCC services
function stop_sdcc()
{
status=`systemctl status httpd | awk '/Active/{print $2}'`
echo "SDCC status: ${status}"
if [ "${status}" != "active" ]; then
    return
fi
echo "Stopping SDCC services (`date`)"
sudo systemctl stop httpd
echo "SDCC services stopped (`date`)"
}

#
# Check MongoDB running and the running role on the both Local and Remote servers
#
mongo_res=`fab --hide=running,warning,aborts,stderr,status -H ${LOCAL_HOST},${REMOTE_HOST1},${REMOTE_HOST2} -- $HOME/scripts/mon_mongodb.sh | awk -v home=$HOME '/Master/ {if($4 == "true"){print $1" master"} else if($4 == "false"){print $1" slave"} else {t=strftime("%Y%m%d_%H-%M-%S",systime());print $1" failure";print $1" failure" >> home"/scripts/logs/mon_mongodb_"t".err"}} /Fatal error/{print $0}'`

# Local role of MongoDB
local_role=`echo "$mongo_res" | awk -v host=${LOCAL_HOST} '{if($1 && index($1,host))print $2}'`
echo "Local: $local_role"

# Remote role of MongoDB
remote_role1=`echo "$mongo_res" | awk -v host=${REMOTE_HOST1} '{if($1 && index($1,host))print $2}'`
echo "Remote (${REMOTE_HOST1}): $remote_role1"

remote_role2=`echo "$mongo_res" | awk -v host=${REMOTE_HOST2} '{if($1 && index($1,host))print $2}'`
echo "Remote (${REMOTE_HOST2}): $remote_role2"

#
# Manage SDCC service
#

echo "Local MongoDB role: $local_role"

if [ "$local_role" != "master" ]; then
stop_sdcc
elif [ "$local_role" == "master" ]; then
start_sdcc
fi


echo "=============== (`date`) Finish script ==============="
echo ""
echo ""

