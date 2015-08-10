require 'vagrant-simplecloud/helpers/client'

module VagrantPlugins
  module SimpleCloud
    module Actions
      class Create
        include Helpers::Client
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @client = client
          @simple_client = simple_client
          @logger = Log4r::Logger.new('vagrant::simplecloud::create')
        end

        def call(env)
          ssh_key_id = [env[:ssh_key_id]]

          # submit new droplet request
          droplet = DropletKit::Droplet.new(name: @machine.config.vm.hostname || @machine.name, \
                                            region: @machine.provider_config.region,\
                                            size: @machine.provider_config.size, image: @machine.provider_config.image)
          result = JSON.parse(@simple_client.droplets.create(droplet))

          # wait for request to complete
          env[:ui].info I18n.t('vagrant_simple_cloud.info.creating')

          raise 'droplet not ready, no actions_ids' unless result['droplet'].has_key?('action_ids')
          @simple_client.wait_for_event(env, result['droplet']['action_ids'].first)

          # assign the machine id for reference in other commands
          @machine.id = result['droplet']['id'].to_s

          # refresh droplet state with provider and output ip address
          droplet = Provider.droplet(@machine, :refresh => true)
          public_network = droplet['networks']['v4'].find { |network| network['type'] == 'public' }
          private_network = droplet['networks']['v4'].find { |network| network['type'] == 'private' }
          env[:ui].info I18n.t('vagrant_simple_cloud.info.droplet_ip', {
            :ip => public_network['ip_address']
          })
          if private_network
            env[:ui].info I18n.t('vagrant_simple_cloud.info.droplet_private_ip', {
              :ip => private_network['ip_address']
            })
          end

          # wait for ssh to be ready
          switch_user = @machine.provider_config.setup?
          user = @machine.config.ssh.username
          @machine.config.ssh.username = 'root' if switch_user

          retryable(:tries => 120, :sleep => 10) do
            next if env[:interrupted]
            raise 'not ready' if !@machine.communicate.ready?
          end

          @machine.config.ssh.username = user

          @app.call(env)
        end

        # Both the recover and terminate are stolen almost verbatim from
        # the Vagrant AWS provider up action
        def recover(env)
          return if env['vagrant.error'].is_a?(Vagrant::Errors::VagrantError)

          if @machine.state.id != :not_created
            terminate(env)
          end
        end

        def terminate(env)
          destroy_env = env.dup
          destroy_env.delete(:interrupted)
          destroy_env[:config_validate] = false
          destroy_env[:force_confirm_destroy] = true
          env[:action_runner].run(Actions.destroy, destroy_env)
        end
      end
    end
  end
end
