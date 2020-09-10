require 'faraday'
require 'json'

module WmpSdk
  class Api

    class << self

      def invoke_access_token
        response = Faraday.get('https://api.weixin.qq.com/cgi-bin/token', {
            grant_type: :client_credential,
            appid:      WmpSdk.configuration.app_id,
            secret:     WmpSdk.configuration.secret,
        })
        raise StandardError, '' unless response.success? || response.status == 200
        response_body = JSON.parse(response.body, symbolize_names: true)
        raise StandardError, '' unless response_body[:access_token]
        response_body
      end


    end

  end
end
