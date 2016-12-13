#!/bin/bash
MONGO_CMD="mongo --eval 'printjson(rs.isMaster())'"
###echo "Mongo CMD: $MONGO_CMD"
mongo_local=`bash -c "$MONGO_CMD" | awk -F':' '/ismaster/{sub(" ","",$2);sub(",","",$2);print $2}'`
echo "Master: $mongo_local"

