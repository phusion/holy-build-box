# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'boxcutter/ubuntu1604'
  config.ssh.forward_agent = true

  config.vm.provider 'vmware_fusion' do |v|
    v.vmx['memsize'] = '1536'
    v.vmx['numvcpus'] = '2'
  end

  config.vm.provision :shell, path: 'dev/install-vagrant.sh'
end
