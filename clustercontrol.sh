#!/bin/bash

echo ________________________________________________________________
KEYFILE=keys/cluster
if [ -f "$KEYFILE" ]; then
    echo "$KEYFILE exists."
else
    echo "$KEYFILE does not exist. Creating ..."
    mkdir -p keys
    ssh-keygen -t rsa -b 4096 -f keys/cluster -q -N ""
fi

docker build -t clustercontrol-talos .
docker-compose run --rm -p 9000:9000 clustercontrol-talos
