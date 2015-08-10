module VagrantPlugins
  module SimpleCloud
    module Errors
      class SimpleCloudError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_simple_cloud.errors")
      end

      class APIStatusError < SimpleCloudError
        error_key(:api_status)
      end

      class JSONError < SimpleCloudError
        error_key(:json)
      end

      class ResultMatchError < SimpleCloudError
        error_key(:result_match)
      end

      class CertificateError < SimpleCloudError
        error_key(:certificate)
      end

      class LocalIPError < SimpleCloudError
        error_key(:local_ip)
      end

      class PublicKeyError < SimpleCloudError
        error_key(:public_key)
      end

      class RsyncError < SimpleCloudError
        error_key(:rsync)
      end
    end
  end
end
