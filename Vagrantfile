# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  num_compute_nodes = (ENV['DEVSTACK_NUM_COMPUTE_NODES'] || 2).to_i

  # ip configuration
  control_ip = "192.168.50.30"
  compute_ip_base = "192.168.50."
  compute_ips = num_compute_nodes.times.collect { |n| compute_ip_base + "#{n+31}" }

  # Devstack Controller
  config.vm.define "devstack-control", primary: true do |control|
    control.vm.box = "ubuntu/trusty64"
    control.vm.hostname = "devstack-control"
    config.vm.provision "ansible" do |ansible|
        ansible.playbook = "playbook.yml"
    end
    #control.vm.network "public_network", ip: "#{control_ip}", bridge: "tap1"
    control.vm.network "private_network", ip: "#{control_ip}", auto_config: true
    control.vm.network "private_network", ip: "0.0.0.0", virtualbox__intnet: "mylocalnet", auto_config: false
    control.vm.provider :virtualbox do |vb|
      # vb.gui = true
      vb.customize ["modifyvm", :id, "--memory", "8192"]
      vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
      vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
      vb.customize ["modifyvm", :id, "--nictype3", "virtio"]
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
      vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
      # vb.customize ["modifyvm", :id, "--cableconnected3", "off"]
    end
  end

  # Devstack Compute Nodes
  num_compute_nodes.times do |n|
    config.vm.define "devstack-compute-#{n+1}", autostart: true do |compute|
      compute_ip = compute_ips[n]
      compute_index = n+1

      compute.vm.box = "ubuntu/trusty64"
      compute.vm.hostname = "devstack-compute-#{compute_index}"
      config.vm.provision "ansible" do |ansible|
          ansible.playbook = "playbook.yml"
      end
      #compute.vm.network "public_network", ip: "#{compute_ip}", bridge: "tap1"
      compute.vm.network "private_network", ip: "#{compute_ip}", auto_config: true
      compute.vm.network "private_network", ip: "0.0.0.0", virtualbox__intnet: "mylocalnet", auto_config: false
      compute.vm.provider :virtualbox do |vb|
        # vb.gui = true
        vb.customize ["modifyvm", :id, "--memory", "8192"]
        vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
        vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
        vb.customize ["modifyvm", :id, "--nictype3", "virtio"]
        vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
        vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
        # vb.customize ["modifyvm", :id, "--cableconnected3", "off"]
      end
    end
  end
end
