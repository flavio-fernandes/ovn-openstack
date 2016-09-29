#!/bin/bash

##set +x
##set -e
cd /home/vagrant/devstack || { echo "cannot cd into devstack dir"; exit 1; }
source openrc admin admin
set -x

nova stop vm1
nova stop vm2
sleep 5
nova force-delete vm1
nova force-delete vm2

nova keypair-delete demo
rm -f id_rsa_demo
nova keypair-list

SG_ICMP=$(neutron security-group-rule-list -f value -c id -c security_group -c protocol -c remote | grep 'default icmp 0.0.0.0/0' | awk '{print $1}')
if [ -n "${SG_ICMP}" ]; then echo "removing sg rule ${SG_ICMP}" ; neutron security-group-rule-delete ${SG_ICMP} ; fi

nova list

neutron router-interface-delete rtr subnet1
neutron router-interface-delete rtr subnet2

neutron router-delete rtr

neutron port-delete local_port1
sudo ovs-vsctl -- --if-exists del-port br-int lport1

neutron subnet-delete subnet1
neutron subnet-delete subnet2

neutron port-list

neutron net-delete net1
neutron net-delete net2

neutron net-list

sudo ovn-sbctl lflow-list
sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | cut -d',' -f3-
