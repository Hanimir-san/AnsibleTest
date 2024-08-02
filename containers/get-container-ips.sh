#! /bin/bash

# TODO: Automatically add the IPs to hosts file
# TODO: Automatically add the IPs to /ansible hosts
# TODO: Automatically add the IPs to list of known hosts

declare -a container_ips

for container_id in $(docker ps --format '{{.ID }}'); do
    container_ip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${container_id}")
    container_name=$(docker inspect --format='{{.Name}}' "${container_id}")
    container_ips=("${container_ips[@]}" "${container_ip}")

    printf "${container_name}\t${container_ip}\n"

done
