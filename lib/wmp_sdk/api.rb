require 'faraday'
require 'json'
require 'wmp_sdk/error'

module WmpSdk
  class Api

    # 登录凭证校验。通过 wx.login 接口获得临时登录凭证 code 后传到开发者服务器调用此接口完成登录流程。
    def self.invoke_auth_session(code)
      response = Faraday.get('https://api.weixin.qq.com/sns/jscode2session', {
          appid:      WmpSdk.configuration.app_id,
          secret:     WmpSdk.configuration.secret,
          js_code:    code,
          grant_type: :authorization_code,
      })
      raise WmpServerError, "Response Status: #{response.status}" unless response.success?
      JSON.parse(response.body, symbolize_names: true)
    end

    # 获取小程序全局唯一后台接口调用凭据（access_token）。调用绝大多数后台接口时都需使用 access_token，开发者需要进行妥善保存。
    def self.invoke_access_token
      response = Faraday.get('https://api.weixin.qq.com/cgi-bin/token', {
          grant_type: :client_credential,
          appid:      WmpSdk.configuration.app_id,
          secret:     WmpSdk.configuration.secret,
      })
      raise WmpServerError, "Response Status: #{response.status}" unless response.success?
      JSON.parse(response.body, symbolize_names: true)
    end

    # 下发小程序和公众号统一的服务消息
    def self.invoke_uniform_message(access_token, openid, mp_template_msg, weapp_template_msg = nil)
      response = Faraday.post('https://api.weixin.qq.com/cgi-bin/message/wxopen/template/uniform_send', { access_token: access_token }) do |request|
        request_body = {
            touser:          openid,
            mp_template_msg: mp_template_msg,
        }
        request_body.merge!(weapp_template_msg: weapp_template_msg) if weapp_template_msg
        request.body = request_body.to_json
      end
      raise WmpServerError, "Response Status: #{response.status}" unless response.success?
      JSON.parse(response.body, symbolize_names: true)
    end

    # 发送订阅消息
    def self.invoke_subscribe_message_send(access_token, openid, template_id, page, data, miniprogram_state = 'formal', lang = 'zh_CN')
      response = Faraday.post('https://api.weixin.qq.com/cgi-bin/message/subscribe/send', { access_token: access_token }) do |request|
        request.body = {
            touser:            openid,
            template_id:       template_id,
            page:              page,
            data:              data,
            miniprogram_state: miniprogram_state,
            lang:              lang,
        }.to_json
      end
      raise WmpServerError, "Response Status: #{response.status}" unless response.success?
      JSON.parse(response.body, symbolize_names: true)
    end

    # 把媒体文件上传到微信服务器。目前仅支持图片。用于发送客服消息或被动回复用户消息。
    def self.invoke_upload_temp_media(access_token, file_name)
      connection = Faraday.new('https://api.weixin.qq.com') do |conn|
        conn.request :multipart
        conn.request :url_encoded
        conn.adapter :net_http
      end
      file       = Faraday::FilePart.new Rails.root.join(file_name).to_s, 'image/jpg'
      response   = connection.post("/cgi-bin/media/upload?access_token=#{access_token}&type=image", { media: file })
      raise WmpServerError, "Response Status: #{response.status}" unless response.success?
      JSON.parse(response.body, symbolize_names: true)
    end

    # 发送客服消息给用户
    def self.send_customer_service_message(access_token, openid, message_type, options = {})
      response = Faraday.post('https://api.weixin.qq.com/cgi-bin/message/custom/send', { access_token: access_token }) do |request|
        request.body = {
            touser:  openid,
            msgtype: message_type,
        }.merge!(options).to_json
      end
      raise WmpServerError, "Response Status: #{response.status}" unless response.success?
      JSON.parse(response.body, symbolize_names: true)
    end

    # 消息推送验证
    def self.validate_customer_service_message(signature, timestamp, nonce)
      Digest::SHA1.hexdigest(
          [WmpSdk.configuration.token, timestamp, nonce].sort.join
      ) == signature
    end


  end
end
