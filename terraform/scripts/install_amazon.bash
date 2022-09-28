#!/bin/bash

set -x

sudo apt update && sudo apt upgrade -y
sudo apt-get update

# For Node
curl -sL https://rpm.nodesource.com/setup_10.x | sudo -E bash -

# For xmlstarlet
# sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# sudo yum update -y

sleep 10

# Setting up Docker
# sudo yum install -y docker
sudo apt install -y docker
sudo usermod -a -G docker ubuntu

# Just to be safe removing previously available java if present
# sudo yum remove -y java

# sudo yum install -y python2-pip jq unzip vim tree biosdevname nc mariadb bind-utils at screen tmux xmlstarlet git java-11-openjdk nc gcc-c++ make nodejs
sudo apt-get install -y default-jre
sudo apt-get install fontconfig

sudo apt install -y python3-pip jq unzip vim tree at screen tmux git gcc make nodejs
sudo -H pip install awscli bcrypt
sudo -H pip install --upgrade awscli
sudo -H pip install --upgrade aws-ec2-assign-elastic-ip

# sudo npm install -g @angular/cli

sudo systemctl enable docker
sudo systemctl enable atd

# sudo yum clean all
# sudo rm -rf /var/cache/yum/