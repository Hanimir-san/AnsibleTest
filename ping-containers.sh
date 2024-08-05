#! /bin/bash

ansible 127.0.0.1 -m ping -u admin -e "ansible_port=50000"