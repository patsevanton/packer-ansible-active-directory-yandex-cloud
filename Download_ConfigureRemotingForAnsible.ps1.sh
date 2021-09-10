#!/bin/bash

if ! command -v curl &> /dev/null
then
    echo "curl could not be found"
    exit
fi

curl https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 --output ConfigureRemotingForAnsible.ps1
