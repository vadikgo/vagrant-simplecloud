require 'droplet_kit'
token='Bqi6Lkd2MMJPy7KUT43LNBLKAtH8tq1v'

class SimpleClient < DropletKit::Client
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

client = SimpleClient.new(access_token: token)
#droplet = DropletKit::Droplet.new(name: 'test', region: 'base', size: '1', image: '123')
#res = JSON.parse(client.droplets.create(droplet))
#p res['droplet']['created_at']

#droplets = client.droplets.all

#droplet = droplets.find{ |d| d['id'].to_s == '31463'  }
#puts droplet['name'] if droplet

puts client.droplets.find(id: 31464).status
