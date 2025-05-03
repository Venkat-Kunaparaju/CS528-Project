#!/bin/bash

SCRIPT_DIR=$(dirname "$0")

function build_image_conditional {
  if ! docker image inspect terrapin-artifacts/$1 > /dev/null 2>&1; then
    docker build $SCRIPT_DIR --target $1 -t terrapin-artifacts/$1
  fi
}

build_image_conditional ext-downgrade-chacha20-poly1305

