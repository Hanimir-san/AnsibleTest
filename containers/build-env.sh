#! /bin/bash

# TODO: Add containers to individual ansible inventory groups
# TODO: Add loopback IPs with descriptive names for each container to hosts file

def_user="admin"
def_pw="password"

docker compose up -d

for container_info in $(docker ps --format '{{.ID}}_{{.Ports}}'); do
    container_port=$(printf "${container_info}" | cut -d "_" -f 2 | sed -rn 's/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:([0-9]+).*/\1/p')
    sshpass -p "${def_pw}" ssh-copy-id -o "StrictHostKeyChecking=no" -p "${container_port}" "${def_user}@127.0.0.1"
done