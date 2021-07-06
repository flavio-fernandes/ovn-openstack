# Devstack with OVN backend in Neutron

This directory contains vagrant file and shell script which can be used to
spawn a devstack based topology with Neutron using OVN backend driver.

This is a simpler version of what Daniel and Slaweq used during the
[OpenInfra Summit workshop](https://github.com/danalsan/vagrants/tree/master/devstack-workshop)
in Octbober 2020.

## Preparation of environment

To prepare this environment You need to have installed:

* [Vagrant](https://www.vagrantup.com/downloads)
* [Libvirt](https://libvirt.org/downloads.html) or [Virtualbox](https://www.virtualbox.org/)
* [Vagrant Libvirt Provider](https://github.com/vagrant-libvirt/vagrant-libvirt) (if using libvirt)

If you need more info on having Vagrant with libvirt, take a look at [this link](http://www.flaviof.com/blog2/post/hacks/vagrant-libvirt/).

## Installation

* Clone this repo and enter the created directory:

```
$ git clone https://github.com/flavio-fernandes/ovn-openstack.git && cd ovn-openstack
```

* Run vagrant:

```
$ vagrant up
```

* Once the configuration step is done you can SSH into the nodes and start
  playing with OVN:

```
$ vagrant status
$ vagrant ssh central
$ sudo ovn-nbctl show
$ sudo ovn-sbctl list Chassis
```

