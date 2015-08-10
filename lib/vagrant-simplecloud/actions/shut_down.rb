require 'vagrant-simplecloud/helpers/client'

module VagrantPlugins
  module SimpleCloud
    module Actions
      class ShutDown
        include Helpers::Client

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @client = client
          @simple_client = simple_client
          @logger = Log4r::Logger.new('vagrant::simplecloud::shut_down')
        end

        def call(env)
          # submit shutdown droplet request
          #result = @client.request("/droplets/#{@machine.id}/shutdown")
          result = JSON.parse(@simple_client.droplet_actions.shutdown(droplet_id: @machine.id.to_s))

          # wait for request to complete
          env[:ui].info I18n.t('vagrant_simple_cloud.info.shutting_down')
          #@client.wait_for_event(env, result['droplet']['event_id'])
          @client.wait_for_event(env, result['action']['id'])

          # refresh droplet state with provider
          Provider.droplet(@machine, :refresh => true)

          @app.call(env)
        end
      end
    end
  end
end
