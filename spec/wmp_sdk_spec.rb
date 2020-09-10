RSpec.describe WmpSdk do

  let(:version) { WmpSdk::VERSION }
  let(:app_id) { 'wx50ff4144e89487ce' }
  let(:secret) { '45682f05a7275aa7a341ca9fd37bb4d7' }
  let(:miniprogram_state) { 'developer' }
  let(:token) { '7783c5477363d5056ac93e9a02bfd8d7' }
  let(:encoding_aes_key) { 'nFbZIerhaXbdzYsG4maN1S5eBgN18O6c2BTbVvN5gRg' }


  it 'has a version number' do
    expect(WmpSdk::VERSION).eql? version
  end


  it 'should be configured successfully' do
    WmpSdk.configure do |config|
      config.app_id            = app_id
      config.secret            = secret
      config.miniprogram_state = miniprogram_state
      config.token             = token
      config.encoding_aes_key  = encoding_aes_key
    end
    expect(WmpSdk.configuration.app_id).eql? app_id
    expect(WmpSdk.configuration.secret).eql? secret
    expect(WmpSdk.configuration.miniprogram_state).eql? miniprogram_state
    expect(WmpSdk.configuration.token).eql? token
    expect(WmpSdk.configuration.encoding_aes_key).eql? encoding_aes_key
  end

  it 'should return access token successfully' do
    access_token_response = WmpSdk::Api.invoke_access_token
    expect(access_token_response[:access_token]).not_to be nil
  end

end
