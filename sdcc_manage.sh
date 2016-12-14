#!/bin/bash

LOCAL_HOST=127.0.0.1
MONGODB_DIR_DEFAULT=/var/lib/mongo
MONGODB_DIR=/data/mongodb
MONGODB_LOG=/var/log/mongodb.log

if [ $# != 2 ]; then 
echo "Usage: $0 <remote host IP, e.g. 10.142.0.3> <local default role (master|slave), e.g. master>"
exit 1
fi

echo "=============== (`date`) Start script ==============="

REMOTE_HOST=$1
LOCAL_ROLE=$2

# Start MongoDB server
function start_mongo()
{
echo "Starting MongoDB server (`date`)"
if [ "$LOCAL_ROLE" == "master" ]; then
sudo mongod --fork --logpath $MONGODB_LOG --dbpath $MONGODB_DIR --master
elif [ "$LOCAL_ROLE" == "slave" ]; then
sudo mongod --fork --logpath $MONGODB_LOG --dbpath $MONGODB_DIR --slave --source $REMOTE_HOST
else
echo "Could not start MongoDB, incorrect role: $LOCAL_ROLE"
return
fi
echo "MongoDB started (`date`)"
}

# Stop MongoDB server
function stop_mongo()
{
echo "Stopping MongoDB server (`date`)"
sudo mongod --shutdown --dbpath $MONGODB_DIR_DEFAULT
sudo mongod --shutdown --dbpath $MONGODB_DIR
echo "MongoDB stopped (`date`)"
}

#
# Check MongoDB running and the running role on the both Local and Remote servers
#
mongo_res=`fab --hide=running,warning,aborts,stderr,status -H $LOCAL_HOST,$REMOTE_HOST -- $HOME/scripts/mon_mongodb.sh | awk -v home=$HOME '/Master/ {if($4 == "true"){print $1" master"} else if($4 == "false"){print $1" slave"} else {t=strftime("%Y%m%d_%H-%M-%S",systime());print $1" failure";print $1" failure" >> home"/scripts/logs/mon_mongodb_"t".err"}} /Fatal error/{print $0}'`

# Local role of MongoDB
local_role=`echo "$mongo_res" | awk -v host=$LOCAL_HOST '{if($1 && index($1,host))print $2}'`
echo "Local: $local_role"

# Remote role of MongoDB
remote_role=`echo "$mongo_res" | awk -v host=$REMOTE_HOST '{if($1 && index($1,host))print $2}'`
echo "Remote: $remote_role"

#
# Manage incorrect role cases 
#
if [ "$local_role" == "$remote_role" ]; then

# Send alert, the same role on the both MongoDB servers 

  if [ "$local_role" == "$LOCAL_ROLE" ]; then
    echo "Local role is correct, do nothing: active ($local_role), defined ($LOCAL_ROLE)"
  else
    echo "Local role is incorrect, restart MongoDB: active ($local_role), defined ($LOCAL_ROLE)"
    stop_mongo
    start_mongo
  fi
elif [ "$local_role" == "failure" ]; then
echo "Local MongoDB is not running, start it"
start_mongo
fi

echo "=============== (`date`) Finish script ==============="
echo ""
echo ""

