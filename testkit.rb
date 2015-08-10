require 'droplet_kit'
require 'net/http'
token=ENV['DO_TOKEN']

class SimpleClient < DropletKit::Client
    def post(path, params = {})
          uri = URI.parse("#{connection_options[:url]}#{path}")
          https = Net::HTTP.new(uri.host,uri.port)
          https.use_ssl = true
          req = Net::HTTP::Post.new(uri.path)
          req['Content-Type'] = connection_options[:headers][:content_type]
          req['Authorization'] = connection_options[:headers][:authorization]
          req.set_form_data(params)
          res = https.request(req)
          puts "Response #{res.code} #{res.message}: #{res.body}"
          JSON.parse(res.body)
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

simple_client = SimpleClient.new(access_token: token)

result = simple_client.post("/v2/droplets/31475/actions", {
  :type => 'rebuild',
  :image => '123'
})

puts result
