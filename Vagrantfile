require 'yaml'

VAGRANT_FILE_API_VERSION = 2

Vagrant.configure(VAGRANT_FILE_API_VERSION) do |config|

  # use the same insecure key over all of the boxes
  config.ssh.insert_key = false

  # mount the source directories for rapid iteration
  [ 'lib/', 'bin/' ].each do |folder|
    config.vm.synced_folder "./#{folder}", "/home/vagrant/easy-e/#{folder}", owner: 'vagrant'
  end

  # mount the gemfile as well
  config.vm.provision 'shell', inline: 'chown vagrant:vagrant -R /home/vagrant/easy-e'
  config.vm.provision 'file', source: './Gemfile', destination: '/home/vagrant/easy-e/Gemfile'

  # the mongodb master server
  config.vm.define 'master' do |s|
    s.vm.box       = 'ubuntu/trusty64'
    s.vm.host_name = 'master'
    s.vm.network 'private_network', ip: "192.168.10.2"
  end

  # the mongodb slave server using wired tiger
  config.vm.define 'slave-wt' do |s|
    s.vm.box       = 'chef/centos-7.0'
    s.vm.host_name = 'slave-wt'
    s.vm.network 'private_network', ip: "192.168.10.3"
  end

  # the mongodb slave server using mmapv1
  config.vm.define 'slave-mmap' do |s|
    s.vm.box       = 'ubuntu/trusty64'
    s.vm.host_name = 'slave-mmap'
    s.vm.network 'private_network', ip: "192.168.10.4"
  end

  # a standalone server
  config.vm.define 'standalone' do |s|
    s.vm.box       = 'ubuntu/trusty64'
    s.vm.host_name = 'standalone'
    s.vm.network 'private_network', ip: "192.168.10.5"

    # for some reason the ansible provisioner only runs concurrently with the
    # correct facts when the definition is in the last box...
    config.vm.provision "ansible" do |ansible|
      ansible.groups = {
        "master" => [ "master" ],
        "slave" => [ "slave-mmap", "slave-wt" ],
        "standalone" => [ "standalone" ]
      }

      ansible.verbose = 'vv'
      ansible.playbook = 'playbook.yml'
      ansible.limit = 'all'
    end
  end
end