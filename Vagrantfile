require 'yaml'

VAGRANT_FILE_API_VERSION = 2

Vagrant.configure(VAGRANT_FILE_API_VERSION) do |config|

  config.ssh.insert_key = false

  config.vm.define 'master' do |s|
    s.vm.box       = 'ubuntu/precise64'
    s.vm.host_name = 'master'
    s.vm.network 'private_network', ip: "192.168.10.2"
  end

  config.vm.define 'slave' do |s|
    s.vm.box       = 'ubuntu/precise64'
    s.vm.host_name = 'slave'
    s.vm.network 'private_network', ip: "192.168.10.3"

    config.vm.provision "ansible" do |ansible|
      ansible.groups = {
        "master" => [ "master" ],
        "slave" => [ "slave" ]
      }
      # ansible.inventory_path = 'vagrant-inventory'
      ansible.playbook = 'playbook.yml'
      ansible.limit = 'all'
    end
  end
end