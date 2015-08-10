module VagrantPlugins
  module SimpleCloud
    class Plugin < Vagrant.plugin('2')
      name 'SimpleCloud'
      description <<-DESC
        This plugin installs a provider that allows Vagrant to manage
        machines using SimpleCloud's API.
      DESC

      config(:simple_cloud, :provider) do
        require_relative 'config'
        Config
      end

      provider(:simple_cloud) do
        require_relative 'provider'
        Provider
      end

      command(:rebuild) do
        require_relative 'commands/rebuild'
        Commands::Rebuild
      end

      command("simplecloud-list", primary: false) do
        require_relative 'commands/list'
        Commands::List
      end
    end
  end
end
