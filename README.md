ovn-openstack
=============

This repo provides an automated way of creating a multi-node devstack
environment with networking-ovn. I mainly use this as a starting point
for whatever I need to get going.

Howto
-----

* tweak file Vagrantfile to taste. If you need to use nondefault
number of compute nodes, you can also set the env variable
$DEVSTACK_NUM_COMPUTE_NODES

* tweak file common_vars.yml . Most likely you want to use
your own networking_ovn_repository .

* vagrant up

* connect to each vm via 'vagrant ssh' and tweak /home/vagrant/devstack/local.conf .
For convenience sake, I lazily keep the tweaked files in /vagrant/junk/ directory,
but that is not something I'm proud of. :)

* from ssh session in each node, invoke:  cd ~/devstack && time ./stack.sh
