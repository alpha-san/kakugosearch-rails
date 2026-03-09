require "spec_helper"

RSpec.describe KakugoSearch::Client do
  let(:base_url) { "http://localhost:7700" }
  let(:client)   { described_class.new }

  before do
    KakugoSearch.configure do |c|
      c.url     = base_url
      c.api_key = nil
    end
  end

  describe "#index_documents" do
    it "POSTs documents to the correct endpoint" do
      stub = stub_request(:post, "#{base_url}/indexes/articles/documents")
               .with(
                 body: [{ id: "1", title: "Hello" }].to_json,
                 headers: { "Content-Type" => "application/json" }
               )
               .to_return(status: 200, body: '{"status":"ok"}', headers: { "Content-Type" => "application/json" })

      result = client.index_documents("articles", [{ id: "1", title: "Hello" }])
      expect(stub).to have_been_requested
      expect(result["status"]).to eq("ok")
    end
  end

  describe "#delete_document" do
    it "sends DELETE to the correct endpoint" do
      stub = stub_request(:delete, "#{base_url}/indexes/articles/documents/42")
               .to_return(status: 200, body: '{"deleted":true}', headers: { "Content-Type" => "application/json" })

      result = client.delete_document("articles", "42")
      expect(stub).to have_been_requested
      expect(result["deleted"]).to be true
    end
  end

  describe "#search" do
    it "GETs the search endpoint with query params" do
      stub = stub_request(:get, "#{base_url}/indexes/articles/search")
               .with(query: hash_including("q" => "rust", "limit" => "10"))
               .to_return(
                 status: 200,
                 body: '{"hits":[{"id":"1","title":"Hello"}]}',
                 headers: { "Content-Type" => "application/json" }
               )

      result = client.search("articles", "rust", limit: 10)
      expect(stub).to have_been_requested
      expect(result["hits"].first["id"]).to eq("1")
    end

    it "includes Authorization header when api_key is set" do
      KakugoSearch.configure { |c| c.api_key = "sk-test" }

      stub = stub_request(:get, /search/)
               .with(headers: { "Authorization" => "Bearer sk-test" })
               .to_return(status: 200, body: '{"hits":[]}', headers: { "Content-Type" => "application/json" })

      KakugoSearch::Client.new.search("articles", "test")
      expect(stub).to have_been_requested
    end
  end
end
