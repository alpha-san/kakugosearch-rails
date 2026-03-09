require "kakugosearch/version"
require "kakugosearch/configuration"
require "kakugosearch/client"

module KakugoSearch
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def client
      @client ||= Client.new(configuration)
    end

    # Reset memoized client when config changes (useful in tests)
    def reset!
      @configuration = nil
      @client        = nil
    end
  end
end

require "kakugosearch/railtie" if defined?(Rails)
