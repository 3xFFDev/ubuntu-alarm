#!/bin/bash

if [ "$EUID" -ne 0 ]; then

  echo -e "\033[31mRun as root.\033[0m"

  exit 1

fi

packages=("at" "mpg123" "findutils")

for package in "${packages[@]}"; do

    is_installed=$(dpkg -l | grep -w "$package")

    if [ -z "$is_installed" ]; then

         apt install -y "$package"
    fi

done

systemctl start atd

systemctl enable atd