#!/bin/bash

echo ________________________________________________________________

KEYFILE="$(pwd)/keys/cluster"
if [ ! -f $KEYFILE.key ]; then
    echo SSH private keyfile is missing!
    echo "Please generate a ssh rsa key pair for the cluster first:"
    echo
    echo Place them here:
    echo ${KEYFILE}
    echo ${KEYFILE}.pub
    echo
    echo Example: ssh-keygen -t rsa -f ${KEYFILE}
    exit 1
fi

KEYFILE="$(pwd)/keys/cluster"
if [ ! -f $KEYFILE.key.pub ]; then
    echo SSH public keyfile is missing!
    echo "Please generate a ssh rsa key pair for the cluster first:"
    echo
    echo Place them here:
    echo ${KEYFILE}
    echo ${KEYFILE}.pub
    echo
    echo Example: ssh-keygen -t rsa -f ${KEYFILE}
    exit 1
fi
# if [ -z ${HCLOUD_TOKEN+x} ]; then
#     echo "HCLOUD_TOKEN must be set!"
#     echo "Please generate a Hetzner Cloud token for accessing hcloud api."
#     echo "Example: export HCLOUD_TOKEN=<<YOURTOKEN_FROM_HCLOUD_CONSOLE>>"
#     exit 1
# else
docker build -t clustercontrol-talos .
docker-compose run --rm -p 9000:9000 clustercontrol-talos
# fi
