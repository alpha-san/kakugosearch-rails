module KakugoSearch
  class Configuration
    attr_accessor :url, :api_key, :default_index

    def initialize
      @url           = "http://localhost:7700"
      @api_key       = ENV["KAKUGOSEARCH_AI_API_KEY"]
      @default_index = nil
    end
  end
end
