#! /bin/bash

# TODO: iterate and ping all the running containers
# TODO: safely store passwords for containers

ansible 127.0.0.2 -m ping -u admin -k -e "ansible_port=50000"