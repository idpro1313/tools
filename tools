#!/bin/bash
echo " "
echo "Update and upgrade OS"
echo " "

sudo apt update && sudo apt upgrade -y

echo " "
echo "Install Ansible"
echo " "

sudo apt install software-properties-common -y
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible -y
  
