#!/usr/bin/env bash
set -o xtrace
set -o errexit

function ubuntu_setup {
    sudo apt-get update
    sudo apt install -y git emacs vim wget
    sudo apt install -y telnet tmate
    sudo apt install -y python3-dev
    sudo apt install -y net-tools tcpdump bmon
}

function install_devstack {
    local type=$1
    local service_ip=$2

    hostname=$(hostname)
    ip=${!hostname}

    ubuntu_setup

    cd
    git clone --depth 1 --no-single-branch https://opendev.org/openstack/neutron.git
    git clone --depth 1 --no-single-branch https://opendev.org/openstack/devstack.git 

    cd devstack

    # FIXME Temporary work around to avoid issue with devstack
    # 799251: Revert "Add route to IPv6 private subnets in ML2/OVN" | https://review.opendev.org/c/openstack/devstack/+/799251
    git fetch "https://review.opendev.org/openstack/devstack" refs/changes/51/799251/2 && git cherry-pick FETCH_HEAD ||:

    cp ~/neutron/devstack/ovn-local.conf.sample ~/devstack/local.conf
    sed -i '/ADMIN_PASSWORD.*/a HOST_IP='${ip}'' ~/devstack/local.conf
    sed -i '/STACK_USER=.*/d' ~/devstack/local.conf
    sed -i '/ADMIN_PASSWORD.*/a STACK_USER=vagrant' ~/devstack/local.conf

    ./stack.sh
}

hostname=$(hostname)

install_devstack master

source ~/devstack/openrc admin admin

cd
sudo iptables -F
sudo ovs-vsctl --may-exist add-br br-ex
sleep 3
sudo ovs-vsctl br-set-external-id br-ex bridge-id br-ex
sudo ovs-vsctl br-set-external-id br-int bridge-id br-int
sudo ovs-vsctl set open . external-ids:ovn-bridge-mappings="public:br-ex"
sudo ovs-vsctl set open . external-ids:ovn-cms-options="enable-chassis-as-gw"

# Add eth2 to br-ex
sudo ovs-vsctl add-port br-ex eth2
sudo ip link set br-ex up
sudo ip link set eth2 up
## sudo ip route add 172.24.4.0/24 dev br-ex


export IMAGE_ID=$(openstack image list -c ID -c Name -f value  | grep cirros | head -n1 |  awk {'print $1'})
cat <<EOT >>~/.bash_profile

abbrev() { a='[0-9a-fA-F]' b=\$a\$a c=\$b\$b; sed "s/\$b-\$c-\$c-\$c-\$c\$c\$c//g"; }

source ~/devstack/openrc admin admin

export IMAGE_ID=${IMAGE_ID}
alias ll='ls -l'

EOT

# FIXME hack around a known issue in secretstorage
sudo sed -i 's/^from cryptography.utils import int_from_bytes$/from cryptography.utils.int import from_bytes/' /usr/lib/python3/dist-packages/secretstorage/dhcrypto.py ||:

[ -e ~/id_rsa_demo ] || { openstack keypair create demo > ~/id_rsa_demo ; chmod 600 ~/id_rsa_demo ; }
for group in $(openstack security group list -f value -c ID); do \
  openstack security group rule create --ingress --ethertype IPv4 --dst-port 22 --protocol tcp $group;
  openstack security group rule create --ingress --ethertype IPv4 --protocol ICMP $group;
done

exit 0
