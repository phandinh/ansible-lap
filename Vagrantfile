# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # The configuration of VirtualBox for all machines
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2000 
    vb.cpus = 2     
  end

  # Define machines
  config.vm.define "controller" do |controller|
    controller.vm.box = "generic/alma9"  # Sử dụng box AlmaLinux 9
    controller.vm.hostname = "controller"
    controller.vm.network :private_network, ip: "192.168.99.99"

    # Provisioning by shell script
    controller.vm.provision "shell", path: "provisioning/controller_setup.sh"
  end

  # Web server 1
  config.vm.define "web1" do |web1|
    web1.vm.box = "generic/alma9"
    web1.vm.hostname = "web1"
    web1.vm.network :private_network, ip: "192.168.99.98"

    # Provisioning by shell script
    web1.vm.provision "shell", path: "provisioning/managed_setup.sh"
  end

  # Database server
  config.vm.define "db1" do |db1|
    db1.vm.box = "generic/alma9"
    db1.vm.hostname = "db1"
    db1.vm.network :private_network, ip: "192.168.99.97"

    # Provisioning by shell script
    db1.vm.provision "shell", path: "provisioning/managed_setup.sh"
  end
  
end
