require 'vagrant-simplecloud/helpers/client'

module VagrantPlugins
  module SimpleCloud
    module Actions
      class Destroy
        include Helpers::Client

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @simple_client = simple_client
          @logger = Log4r::Logger.new('vagrant::simplecloud::destroy')
        end

        def call(env)
          # submit destroy droplet request
          @simple_client.delete("/v2/droplets/#{@machine.id}")

          env[:ui].info I18n.t('vagrant_simple_cloud.info.destroying')

          # set the machine id to nil to cleanup local vagrant state
          @machine.id = nil

          @app.call(env)
        end
      end
    end
  end
end
