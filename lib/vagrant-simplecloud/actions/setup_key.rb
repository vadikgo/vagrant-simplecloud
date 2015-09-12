require 'vagrant-simplecloud/helpers/client'

module VagrantPlugins
  module SimpleCloud
    module Actions
      class SetupKey
        include Helpers::Client

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @simple_client = simple_client
          @logger = Log4r::Logger.new('vagrant::simplecloud::setup_key')
        end

        # TODO check the content of the key to see if it has changed
        def call(env)
            ssh_key_name = @machine.provider_config.ssh_key_name
            # assigns existing ssh key id to env for use by other commands
            res = @simple_client.request('/v2/account/keys')
            key_data = res.fetch('ssh_keys').select {|a| a['name'] == ssh_key_name}.first
            if key_data.nil?
                env[:ssh_key_id] = create_ssh_key(ssh_key_name, env)
            else
                env[:ssh_key_id] = key_data['id']
            end
            env[:ui].info I18n.t('vagrant_simple_cloud.info.using_key', {:name => ssh_key_name})
            @app.call(env)
        end

        private

        def create_ssh_key(name, env)
          # assumes public key exists on the same path as private key with .pub ext
          path = @machine.config.ssh.private_key_path
          path = path[0] if path.is_a?(Array)
          path = File.expand_path(path, @machine.env.root_path)
          pub_key = SimpleCloud.public_key(path)

          env[:ui].info I18n.t('vagrant_simple_cloud.info.creating_key', {
            :name => name
          })

          result = @simple_client.post('/v2/account/keys', {
            :name => name,
            :public_key => pub_key
          })
          result['ssh_key']['id']
        end
      end
    end
  end
end
