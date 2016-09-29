#!/bin/bash

set +x
set -e
cd /home/vagrant/devstack || { echo "cannot cd into devstack dir"; exit 1; }
source openrc admin admin
set -x

neutron net-list

# Create an ssh key, if there is not one yet
if [[ ! -f id_rsa_demo ]]; then
    nova keypair-add demo > id_rsa_demo
    chmod 600 id_rsa_demo
fi

DEF_SG=$( neutron security-group-list -f value -c id -c name | grep default | head -1 | awk '{print $1}')
neutron security-group-rule-create --direction ingress --protocol icmp --remote-ip-prefix '0.0.0.0/0' ${DEF_SG}
neutron security-group-rule-create --direction ingress --protocol tcp --remote-ip-prefix '0.0.0.0/0' ${DEF_SG}

neutron router-create rtr

neutron net-create net1
neutron subnet-create net1 10.1.0.0/24 --name subnet1
neutron router-interface-add rtr subnet1

neutron net-create net2
neutron subnet-create net2 10.2.0.0/24 --name subnet2
neutron router-interface-add rtr subnet2

IMG_ID=$(openstack image list | grep 'cirros-0.3..-x86_64-uec\s' | tail -1 | awk '{print $2}')
NET1_ID=$(neutron net-show net1 -F id --format=value)
NET2_ID=$(neutron net-show net2 -F id --format=value)

nova boot --poll --flavor m1.nano --image $IMG_ID --key-name demo --nic net-id=${NET1_ID} vm1
nova boot --poll --flavor m1.nano --image $IMG_ID --key-name demo --nic net-id=${NET2_ID} vm2

NOVA_VM1=$(nova list | grep vm1)
NOVA_VM2=$(nova list | grep vm2)

# make sure vms are up...
echo $NOVA_VM1 | grep -i active || { echo "vm1 not active"; exit 1; }
echo $NOVA_VM2 | grep -i active || { echo "vm2 not active"; exit 1; }

VM1_IP=$(echo $NOVA_VM1 | awk -F'net1=' '{print $2}' | awk '{print $1}')
VM2_IP=$(echo $NOVA_VM2 | awk -F'net2=' '{print $2}' | awk '{print $1}')

# create local port to get to vm1
neutron port-create --name local_port1 net1

RTR_IP1_RAW=$(neutron router-port-list rtr -F fixed_ips --format=value | grep 10\.1\.)
RTR_IP1=$(echo $RTR_IP1_RAW | awk -F'"ip_address": ' '{print $2}' | awk -F'"' '{print $2}')
RTR_IP2_RAW=$(neutron router-port-list rtr -F fixed_ips --format=value | grep 10\.2\.)
RTR_IP2=$(echo $RTR_IP2_RAW | awk -F'"ip_address": ' '{print $2}' | awk -F'"' '{print $2}')

LPORT1_IFACE_ID=$(neutron port-show local_port1 -F id --format=value)
LPORT1_MAC=$(neutron port-show local_port1 -F mac_address --format=value)
LPORT1_FIXED_IPS=$(neutron port-show local_port1 -F fixed_ips --format=value)
LPORT1_IP=$(echo $LPORT1_FIXED_IPS | awk -F'"ip_address": ' '{print $2}' | awk -F'"' '{print $2}')

sudo ovs-vsctl --may-exist add-port br-int lport1 -- \
   set Interface lport1 external_ids:iface-id=$LPORT1_IFACE_ID type=internal

sudo ip link set dev lport1 address $LPORT1_MAC
sudo ip addr add ${LPORT1_IP}/24 dev lport1
sudo ip link set dev lport1 up

ping -w 3 -c 1 $VM1_IP || { echo "vm1 not responding"; exit 1; }

VM1_SSH="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i id_rsa_demo cirros@${VM1_IP}"

SANITY=$(eval "$VM1_SSH hostname 2>/dev/null")
[[ "$SANITY" == "vm1" ]] || { echo "ssh to vm1 failed"; exit 1; }

eval "$VM1_SSH ping -w 3 -c 1 $VM2_IP" || { echo "vm1 was not able to ping $VM2_IP"; exit 1; }

eval "$VM1_SSH ping -w 3 -c 1 $RTR_IP1" || { echo "vm1 was not able to ping $RTR_IP1"; exit 1; }
eval "$VM1_SSH ping -w 3 -c 1 $RTR_IP2" || { echo "vm1 was not able to ping $RTR_IP2"; exit 1; }

echo 'happy happy, joy joy!!!'
exit 0

