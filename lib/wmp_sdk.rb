require 'wmp_sdk/version'
require 'wmp_sdk/api'
require 'wmp_sdk/configuration'

module WmpSdk

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end
  end


end
