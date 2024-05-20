#!/bin/bash

# Install some dependancies
rpm -qi python3-pip python3-virtualenv > /dev/null
if [ $? != 0 ]; then
    dnf -y install python3-pip
fi

# Update the python alternatives if needed
if [ ! -e /usr/bin/python ]; then
    alternatives --set python /usr/bin/python3
fi

# Create the virtual environment
if [ ! -d /root/ansible_venv ]; then

    # Set up the python virtual env
    python3 -m venv --system-site-packages /root/ansible_venv

fi

# Install required packages
. /root/ansible_venv/bin/activate
pip install -r ./osp16-requirements.txt
deactivate

# Generate a token(non core testing when we have the vars set)
if [[ "$PUBCLOUD_USERNAME" != "" ]] && [[ "$PUBCLOUD_API_KEY" != "" ]] && [[ "$PUBCLOUD_TENANT_ID" != "" ]]; then
    . /root/ansible_venv/bin/activate
    ./tests/maasutils.py \
        --username "${PUBCLOUD_USERNAME}" \
        --api-key "${PUBCLOUD_API_KEY}" \
        get_token_url
    deactivate

    # Update the token if vars file exists
    if [ -e /home/stack/user_maas_variables.yml ]; then
        echo "Refreshing the maas_auth_token in /home/stack/user_maas_variables.yml"
        . /root/maas-vars.rc
        sed -i -e "s/^maas_auth_token:.*/maas_auth_token: \"${MAAS_AUTH_TOKEN}\"/g" /home/stack/user_maas_variables.yml
    fi
fi

# Bomb if the /home/stack/user_maas_variables.yml doesn't exist.
if [ ! -e /home/stack/user_maas_variables.yml ]; then
    echo
    echo "Please read the documentation and create the /home/stack/user_maas_variables.yml config file and set up any entities and agents as needed."
    echo
fi

echo
echo "Example Playbook Usage Post Configuration:
cd /opt/rpc-maas/
. /root/ansible_venv/bin/activate
ansible-playbook -i /opt/rpc-maas/inventory/rpcr_dynamic_inventory.py -e @/home/stack/user_maas_variables.yml  playbooks/site.yml
deactivate
"
echo