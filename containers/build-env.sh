#! /bin/bash

# set -o errexit
set -o nounset
set -o pipefail

# Check that script is being run with user admin privileges
if [ $EUID != 0 ];
then
    echo "This script must be run with superuser privileges!"
    exit 1 
fi

# TODO: Add containers to individual ansible inventory groups
# TODO: Add containers to user known hosts

current_dir=$(readlink -f .)

# Get current user directories in case script is sudoed
user_home=$( cat /etc/passwd| grep "$USERNAME" | cut -d: -f6 )
user_ssh_dir="${user_home}/.ssh"
user_pub_key="${user_ssh_dir}/id_rsa.pub"

def_user="admin"
def_pw="password"

# Create ssh key pair if none exists for current server
if [ ! -f "${user_pub_key}" ]; then
    echo "Public key not found! Creating new key..."
    cd "${user_ssh_dir}"
    ssh-keygen -t rsa -b 4096 -N " " -f "${user_ssh_dir}/id_rsa"
    cd -
fi

echo "Starting Docker containers..."
sudo -iu "${USERNAME}" docker compose -f "${current_dir}/compose.yml" up -d

# Remove previous test suite host entries if any
# cat /etc/hosts | perl -0777 -pe "s/# Added by Ansible Test Suite(.|\n)+# End of section//g" > /etc/hosts

# Add new hosts entries so we have names to reach the containers with
echo "Adding names for containers to hosts file..."

declare -i range_current=0
declare -i range_end=255
echo "# Added by Ansible Test Suite" >> /etc/hosts
for container_name in $(sudo -iu "${USERNAME}" docker ps --format '{{.Names}}'); do
    container_name=$(echo "${container_name}" | sed -E s/-[0-9]$//g | sed -E s/^containers-//g)
    echo "${container_name}"
    echo "${range_current}"

    while ((range_current<=range_end)); do
        ((range_current++))
        container_ip="127.0.0.${range_current}"
        if [ $(cat /etc/hosts | grep -c "${container_ip}"}) -lt 1 ]; then
            echo "${container_ip}   ${container_name}" >> /etc/hosts
            break
        fi
    done
done
echo "# End of section" >> /etc/hosts

# Add public key to all containers
echo "Adding public key to containers..."
for container_info in $(sudo -iu "${USERNAME}" docker ps --format '{{.ID}}_{{.Ports}}'); do
    container_port=$(printf "${container_info}" | cut -d "_" -f 2 | sed -rn 's/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:([0-9]+).*/\1/p')
    sudo -iu "${USERNAME}" sshpass -p "${def_pw}" ssh-copy-id -o "StrictHostKeyChecking=no" -p "${container_port}" "${def_user}@127.0.0.1"
done
