require 'vagrant-simplecloud/helpers/result'
require 'json'
require 'uri'
require 'net/http'
require 'net/https'

module VagrantPlugins
  module SimpleCloud
    module Helpers
      module Client
        def simple_client
          @simple_client ||= SimpleClient.new(@machine)
        end
      end
      class SimpleClient
          include Vagrant::Util::Retryable

          def initialize(machine)
            @logger = Log4r::Logger.new('vagrant::simplecloud::apiclient')
            @config = machine.provider_config
            @url = "https://api.simplecloud.ru"
          end

          def delete(path, params = {})
              self.request(path, params, :delete)
          end

          def post(path, params = {})
              self.request(path, params, :post)
          end

          def request(path, params = {}, method = :get)
                @logger.info "Request: #{@url}#{path} #{params}"
                uri = URI.parse("#{@url}#{path}")
                https = Net::HTTP.new(uri.host,uri.port)
                https.use_ssl = true
                req = case method
                    when :get
                        Net::HTTP::Get.new(uri.path)
                    when :post
                        Net::HTTP::Post.new(uri.path)
                    when :delete
                        Net::HTTP::Delete.new(uri.path)
                end
                req['Content-Type'] = "application/json"
                req['Authorization'] = "Bearer #{@config.token}"
                req.set_form_data(params)
                res = https.request(req)
                unless /^2\d\d$/ =~ res.code.to_s
                  raise "Server response error #{res.code} #{path} #{params} #{res.message} #{res.body}"
                end
                JSON.parse(res.body) unless res.body.nil?
          end

          def wait_for_event(env, id)
            retryable(:tries => 120, :sleep => 10) do
              # stop waiting if interrupted
              next if env[:interrupted]

              # check action status
              result = self.request("/v2/actions/#{id}")

              yield result if block_given?
              raise 'not ready' if result['action']['status'] != 'completed'
            end
          end
      end
    end
  end
end
