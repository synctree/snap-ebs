require 'yaml'

VAGRANT_FILE_API_VERSION = 2

Vagrant.configure(VAGRANT_FILE_API_VERSION) do |config|

  count = 1
  
  %w(mysql-master mysql-slave).each do |role|
    count += 1
    config.vm.define role do |s|
      s.vm.box       = 'ubuntu/precise64'
      s.vm.host_name = role
      s.vm.network 'private_network', ip: "192.168.10.#{count}"

      s.vm.provision "ansible" do |ansible|
        ansible.groups = {
          "mysql-master" => [ "mysql-master" ],
          "mysql-slave" => [ "mysql-slave" ]
        }
        ansible.limit          = role
        # ansible.inventory_path = 'provision'
        ansible.playbook       = 'playbook.yml'
      end
    end
  end
end