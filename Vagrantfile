IPS = {central:   '192.168.150.100',
       central_2: '172.24.4.100',
      }

RAM = 8000
VCPUS = 4

Vagrant.configure(2) do |config|

    vm_memory = ENV['VM_MEMORY'] || RAM
    vm_cpus = ENV['VM_CPUS'] || VCPUS

    config.vm.provider 'libvirt' do |lb|
        lb.nested = true
        lb.memory = vm_memory
        lb.cpus = vm_cpus
        lb.suspend_mode = 'managedsave'
        lb.storage_pool_name = 'default'
        lb.qemu_use_session = false
    end

    # VirtualBox specific configuration
    config.vm.provider "virtualbox" do |vb|
        vb.memory = vm_memory
        vb.cpus = vm_cpus
        vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
        vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
        vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
        vb.customize ["modifyvm", :id, "--nictype3", "virtio"]
        vb.customize [
           "guestproperty", "set", :id,
           "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000]
    end

    config.ssh.forward_agent = true
    config.vm.hostname = "ovnhost"
    config.vm.box = "generic/ubuntu2004"
#    config.vm.box = "centos/8"
    config.vm.synced_folder './', '/vagrant', type: 'rsync'

     # central as controller node (northd/southd)
    config.vm.define 'central', primary: true, autostart: true do |central|
        central.vm.network 'private_network', ip: IPS[:central]
        central.vm.network 'private_network', ip: IPS[:central_2], auto_config: false,
                           :libvirt__dhcp_enabled => "no"
        central.vm.hostname = 'central'
        central.vm.provision :shell do |shell|
            shell.privileged = false
            shell.path = 'central.sh'
            shell.env = IPS
        end
    end

end
