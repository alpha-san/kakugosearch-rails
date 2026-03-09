require "net/http"
require "json"
require "uri"

module KakugoSearch
  class Client
    def initialize(config = KakugoSearch.configuration)
      @config = config
    end

    # POST /indexes/{index}/documents
    def index_documents(index, docs)
      uri = URI("#{@config.url}/indexes/#{index}/documents")
      request(Net::HTTP::Post, uri, docs)
    end

    # DELETE /indexes/{index}/documents/{id}
    def delete_document(index, id)
      uri = URI("#{@config.url}/indexes/#{index}/documents/#{id}")
      request(Net::HTTP::Delete, uri)
    end

    # GET /indexes/{index}/search
    def search(index, query, limit: 20, ai: false, ai_weight: 0.3)
      params = URI.encode_www_form(q: query, limit: limit, ai: ai, ai_weight: ai_weight)
      uri    = URI("#{@config.url}/indexes/#{index}/search?#{params}")
      request(Net::HTTP::Get, uri)
    end

    private

    def request(method_class, uri, body = nil)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        req = method_class.new(uri)
        req["Content-Type"] = "application/json"
        req["Accept"]       = "application/json"
        req["Authorization"] = "Bearer #{@config.api_key}" if @config.api_key
        req.body = body.to_json if body
        response = http.request(req)
        JSON.parse(response.body)
      end
    end
  end
end
