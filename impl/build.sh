#!/bin/bash

SCRIPT_DIR=$(dirname "$0")

# OpenSSH client 9.5p1
if ! docker image inspect terrapin-artifacts/openssh-client:9.5p1 > /dev/null 2>&1; then
  docker build $SCRIPT_DIR/openssh --target openssh-client -t terrapin-artifacts/openssh-client:9.5p1
fi
# OpenSSH server 9.5p1
if ! docker image inspect terrapin-artifacts/openssh-server:9.5p1 > /dev/null 2>&1; then
  docker build $SCRIPT_DIR/openssh --target openssh-server -t terrapin-artifacts/openssh-server:9.5p1
fi

