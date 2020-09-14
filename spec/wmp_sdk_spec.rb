RSpec.describe WmpSdk do

  let(:version) { WmpSdk::VERSION }
  let(:app_id) { '3fec3d94074cc7cc19700497cb77f73c' }
  let(:secret) { 'ec135e6bae59fa5dd4358ad9339adf6a' }
  let(:miniprogram_state) { 'developer' }
  let(:token) { '55034443a553f13df5c64a55d4c4eaef' }
  let(:encoding_aes_key) { '643550f92e24aecf90a1c4b914036b4c' }

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
    response = WmpSdk::Api.invoke_access_token
    expect(response).not_to be nil
  end

end
