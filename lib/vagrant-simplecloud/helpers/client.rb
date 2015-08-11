require 'vagrant-simplecloud/helpers/result'
require 'faraday'
require 'json'
require 'droplet_kit'
require 'uri'
require 'net/http'
require 'net/https'

module VagrantPlugins
  module SimpleCloud
    module Helpers
      module Client
        def client
          @client ||= ApiClient.new(@machine)
        end
        def simple_client
          @simple_client ||= SimpleClient.new(access_token: @machine.provider_config.token)
        end
      end
      class SimpleClient < DropletKit::Client
          include Vagrant::Util::Retryable

          def post(path, params = {})
                uri = URI.parse("#{connection_options[:url]}#{path}")
                https = Net::HTTP.new(uri.host,uri.port)
                https.use_ssl = true
                req = Net::HTTP::Post.new(uri.path)
                req['Content-Type'] = connection_options[:headers][:content_type]
                req['Authorization'] = connection_options[:headers][:authorization]
                req.set_form_data(params)
                res = https.request(req)
                unless /^2\d\d$/ =~ res.code.to_s
                  raise "Server response error #{res.code} #{path} #{params} #{res.message} #{res.body}"
                end
                JSON.parse(res.body)
          end

          def wait_for_event(env, id)
            retryable(:tries => 120, :sleep => 10) do
              # stop waiting if interrupted
              next if env[:interrupted]
              # check action status
              result = self.actions.find(id: id)
              yield result if block_given?
              raise 'not ready' if result.status != 'completed'
            end
          end

          private
          def connection_options
              {
                  url: "https://api.simplecloud.ru",
                  headers: {
                      content_type: 'application/json',
                      authorization: "Bearer #{access_token}"
                      }
              }
          end
      end
      class ApiClient
        include Vagrant::Util::Retryable

        def initialize(machine)
          @logger = Log4r::Logger.new('vagrant::simplecloud::apiclient')
          @config = machine.provider_config
          @client = Faraday.new({
            :url => 'https://api.simplecloud.ru/',
            :ssl => {
              :ca_file => @config.ca_path
            }
          })
        end

        def delete(path, params = {}, method = :delete)
          @client.request :url_encoded
          request(path, params, :delete)
        end

        def post(path, params = {}, method = :post)
          @client.headers['Content-Type'] = 'application/json'
          request(path, params, :post)
        end

        def request(path, params = {}, method = :get)
          begin
            @logger.info "Request: #{path} #{params}"
            result = @client.send(method) do |req|
              req.url path, params
              req.headers['Authorization'] = "Bearer #{@config.token}"
            end
          rescue Faraday::Error::ConnectionFailed => e
            # TODO this is suspect but because farady wraps the exception
            #      in something generic there doesn't appear to be another
            #      way to distinguish different connection errors :(
            if e.message =~ /certificate verify failed/
              raise Errors::CertificateError
            end

            raise e
          end

          unless method == :delete
            begin
              body = JSON.parse(result.body)
              @logger.info "Response: #{body}"
              next_page = body["links"]["pages"]["next"] rescue nil
              unless next_page.nil?
                uri = URI.parse(next_page)
                new_path = path.split("?")[0]
                next_result = self.request("#{new_path}?#{uri.query}")
                req_target = new_path.split("/")[-1]
                body["#{req_target}"].concat(next_result["#{req_target}"])
              end
            rescue JSON::ParserError => e
              raise(Errors::JSONError, {
                :message => e.message,
                :path => path,
                :params => params,
                :response => result.body
              })
            end
          end

          unless /^2\d\d$/ =~ result.status.to_s
            raise(Errors::APIStatusError, {
              :path => path,
              :params => params,
              :status => result.status,
              :response => body.inspect
            })
          end

          Result.new(body)
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
