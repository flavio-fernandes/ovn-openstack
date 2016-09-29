#!/usr/bin/env bash
#

export TNT_ID=${TNT_ID:-1}
export SUBNETS_PER_TENANT=${SUBNETS_PER_TENANT:-2}
export VMS_PER_SUBNET=${VMS_PER_SUBNET:-2}

set +x
set -e
cd /home/vagrant/devstack || { echo "cannot cd into devstack dir"; exit 1; }
source openrc admin admin
set -x

## keystone tenant-create --name=l3tenant${TNT_ID} --enabled=true
openstack project create --enable l3tenant${TNT_ID}

## keystone user-create --name=l3user${TNT_ID} --pass=l3user${TNT_ID} --email=l3user${TNT_ID}@example.com
openstack user create --project l3tenant${TNT_ID} --password=l3user${TNT_ID} --email=l3user${TNT_ID}@example.com l3user${TNT_ID}

## keystone user-role-add --user=l3user${TNT_ID} --role=Member --tenant=l3tenant${TNT_ID}
openstack role add --project l3tenant${TNT_ID} --user l3user${TNT_ID} Member

source openrc l3user${TNT_ID} l3tenant${TNT_ID} ; export OS_PASSWORD=l3user${TNT_ID}

if [ ! -f id_rsa_demo.pub ]; then ssh-keygen -t rsa -b 2048 -N '' -f id_rsa_demo; fi
nova keypair-add --pub-key  id_rsa_demo.pub  demo_key

nova secgroup-create sec1 sec1
nova secgroup-add-rule sec1 icmp -1 -1 0.0.0.0/0
for x in tcp udp; do nova secgroup-add-rule sec1 ${x} 1 65535 0.0.0.0/0 ; done

nova secgroup-list-rules sec1


neutron router-create l3tenant${TNT_ID}router

for netIndex in $(seq 1 ${SUBNETS_PER_TENANT}) ; do \
  neutron net-create net${netIndex}
  neutron subnet-create --gateway=${netIndex}.0.0.254 --name=subnet${netIndex} net${netIndex} ${netIndex}.0.0.0/24 --enable-dhcp
  neutron router-interface-add l3tenant${TNT_ID}router subnet${netIndex}
  sleep 2
done
neutron router-port-list l3tenant${TNT_ID}router

##IMAGE=$(nova image-list | grep 'cirros.*uec\s' | tail -1 | awk '{print $2}')
IMAGE=$(openstack image list | grep 'cirros-0.3..-x86_64-uec\s' | tail -1 | awk '{print $2}')

for netIndex in $(seq 1 ${SUBNETS_PER_TENANT}) ; do \
    NETID=$(neutron net-list | grep -w net${netIndex} | awk '{print $2}')
    for vmIndex in $(seq 1 ${VMS_PER_SUBNET}) ; do \
        VMNAME="tnt${TNT_ID}_net${netIndex}_vm${vmIndex}"
        echo creating ${VMNAME}
        nova boot --poll --flavor m1.nano --image ${IMAGE} --nic net-id=${NETID} \
        --security-groups sec1 --key-name demo_key \
        ${VMNAME}
        sleep 1
    done
done

#
# source openrc l3user1 l3tenant1 ; export OS_PASSWORD=l3user1
# source openrc l3user2 l3tenant2 ; export OS_PASSWORD=l3user2
# source openrc l3user${TNT_ID} l3tenant${TNT_ID} ; export OS_PASSWORD=l3user${TNT_ID}
# source openrc admin admin
#

