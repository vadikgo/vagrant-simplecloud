Vagrant.configure('2') do |config|

  config.vm.define :swift8 do |swift8|
    swift8.vm.hostname = "swift8"
  end

  config.vm.provider :simple_cloud do |provider, override|
    override.ssh.private_key_path = '~/.ssh/id_rsa'
    override.vm.box = 'simple_cloud'
    override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"

    provider.token = ENV['DO_TOKEN']
    provider.image = '123'
    provider.region = 'base'
    provider.size = "1"
  end
end
