require 'yaml'

VAGRANT_FILE_API_VERSION = 2

Vagrant.configure(VAGRANT_FILE_API_VERSION) do |config|

  count = 1
  
  %w(master slave).each do |role|
    count += 1
    config.vm.define role do |s|
      s.vm.box       = 'ubuntu/precise64'
      s.vm.host_name = role
      s.vm.network 'private_network', ip: "192.168.10.#{count}"

      s.vm.provision "ansible" do |ansible|
        ansible.groups = {
          "master" => [ "master" ],
          "slave" => [ "slave" ]
        }
        ansible.playbook = 'playbook.yml'
        ansible.verbose = 'vvv'
      end
    end
  end
end