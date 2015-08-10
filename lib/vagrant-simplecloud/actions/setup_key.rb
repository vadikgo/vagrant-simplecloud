require 'vagrant-simplecloud/helpers/client'

module VagrantPlugins
  module SimpleCloud
    module Actions
      class SetupKey
        include Helpers::Client

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @client = client
          @simple_client = simple_client
          @logger = Log4r::Logger.new('vagrant::simplecloud::setup_key')
        end

        # TODO check the content of the key to see if it has changed
        def call(env)
            ssh_key_name = @machine.provider_config.ssh_key_name
            # assigns existing ssh key id to env for use by other commands
            @simple_client.ssh_keys.all().each do |key|
                if key["name"] == ssh_key_name
                    env[:ssh_key_id] = key["id"]
                    env[:ui].info I18n.t('vagrant_simple_cloud.info.using_key', {
                      :name => ssh_key_name
                    })
                    @app.call(env)
                    return
                end
            end
            env[:ssh_key_id] = create_ssh_key(ssh_key_name, env)
            @app.call(env)
        end

        private

        def create_ssh_key(name, env)
          # assumes public key exists on the same path as private key with .pub ext
          path = @machine.config.ssh.private_key_path
          path = path[0] if path.is_a?(Array)
          path = File.expand_path(path, @machine.env.root_path)
          pub_key = SimpleCloud.public_key(path)
          ssh_key = DropletKit::SSHKey.new(name: name, public_key: pub_key)
          result = @simple_client.ssh_keys.create(ssh_key)
          env[:ui].info I18n.t('vagrant_simple_cloud.info.creating_key', {
            :name => name
          })
          result.id
        end
      end
    end
  end
end
