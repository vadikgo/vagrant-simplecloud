require 'vagrant-simplecloud/helpers/client'

module VagrantPlugins
  module SimpleCloud
    module Actions
      class Reload
        include Helpers::Client

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @simple_client = simple_client
          @logger = Log4r::Logger.new('vagrant::simplecloud::reload')
        end

        def call(env)
          # submit reboot droplet request
          result = @simple_client.post("/v2/droplets/#{@machine.id}/actions", {:type => 'reboot'})

          # wait for request to complete
          env[:ui].info I18n.t('vagrant_simple_cloud.info.reloading')
          @simple_client.wait_for_event(env, result['action']['id'])

          @app.call(env)
        end
      end
    end
  end
end
