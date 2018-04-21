Vagrant.configure('2') do |config|
  #config.vm.box      = 'ubuntu/yakkety64' # 16.10
  config.vm.box = "ubuntu/xenial64"

  config.vm.hostname = 'redu'

  #config.vm.network :forwarded_port, guest: 3000, host: 3000, host_ip: "127.0.0.1"

  #Indeorum
  #config.vm.network "public_network", ip: "192.168.0.165", guest: 3000, host: 3000

  #Home
  #config.vm.network "public_network", ip: "192.168.1.120", guest: 3000, host: 3000

  #Felipe
  config.vm.network "public_network", ip: "192.168.1.115", guest: 3000, host: 3000

  #Anglo
  #config.vm.network "public_network", ip: "192.168.43.30", guest: 3000, host: 3000


  config.vm.provider 'virtualbox' do |v|
    v.memory = 2048
    v.cpus = 2
  end
   # config.vm.synced_folder ".", "/var/www", :mount_options => ["dmode=777", "fmode=666"]
  config.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777", "fmode=666"]
end

