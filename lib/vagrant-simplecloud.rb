require 'vagrant-simplecloud/version'
require 'vagrant-simplecloud/plugin'
require 'vagrant-simplecloud/errors'

module VagrantPlugins
  module SimpleCloud
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end

    def self.public_key(private_key_path)
      File.read("#{private_key_path}.pub") 
    rescue
      raise Errors::PublicKeyError, :path => "#{private_key_path}.pub"
    end

    I18n.load_path << File.expand_path('locales/en.yml', source_root)
    I18n.reload!
  end
end
