#!/bin/bash

if [ $# != 1 ]; then 
echo "Usage: $0 <remote host>"
exit 1
fi

LOCAL_HOST=127.0.0.1
REMOTE_HOST=$1

mongo_res=`fab --hide=running,warning,aborts,stderr,status -H $LOCAL_HOST,$REMOTE_HOST -- $HOME/scripts/mon_mongodb.sh | awk -v home=$HOME '/Master/ {if($4 == "true"){print $1" master"} else if($4 == "false"){print $1" slave"} else {t=strftime("%Y%m%d_%H-%M-%S",systime());print $1" failure";print $1" failure" >> home"/scripts/logs/mon_mongodb_"t".err"}} /Fatal error/{print $0}'`

local_res=`echo "$mongo_res" | awk -v host=$LOCAL_HOST '{if($1 && index($1,host))print $2}'`
echo "Local: $local_res"
remote_res=`echo "$mongo_res" | awk -v host=$REMOTE_HOST '{if($1 && index($1,host))print $2}'`
echo "Remote: $remote_res"
