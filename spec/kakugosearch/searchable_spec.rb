require "spec_helper"

RSpec.describe KakugoSearch::Searchable do
  let(:base_url) { "http://localhost:7700" }

  before do
    KakugoSearch.configure { |c| c.url = base_url; c.api_key = nil }

    # Default stub so unexpected calls don't blow up; individual tests override
    stub_request(:any, /localhost:7700/).to_return(
      status: 200, body: '{"status":"ok"}', headers: { "Content-Type" => "application/json" }
    )
  end

  describe "after_save callback" do
    it "indexes the document with the configured fields" do
      stub = stub_request(:post, "#{base_url}/indexes/articles/documents")
               .to_return(status: 200, body: '{"status":"ok"}', headers: { "Content-Type" => "application/json" })

      Article.create!(title: "Rust Guide", body: "Learn Rust", slug: "/rust")
      expect(stub).to have_been_requested
    end

    it "sends the correct field mapping" do
      stub = stub_request(:post, "#{base_url}/indexes/articles/documents")
               .with { |req|
                 payload = JSON.parse(req.body)
                 doc = payload.first
                 doc["title"] == "My Post" && doc["body"] == "content here" && doc["url"] == "/my-post"
               }
               .to_return(status: 200, body: '{"status":"ok"}', headers: { "Content-Type" => "application/json" })

      Article.create!(title: "My Post", body: "content here", slug: "/my-post")
      expect(stub).to have_been_requested
    end
  end

  describe "after_destroy callback" do
    it "deletes the document from the index" do
      article = Article.create!(title: "To Delete", body: "bye", slug: "/bye")
      id = article.id.to_s

      stub = stub_request(:delete, "#{base_url}/indexes/articles/documents/#{id}")
               .to_return(status: 200, body: '{"deleted":true}', headers: { "Content-Type" => "application/json" })

      article.destroy
      expect(stub).to have_been_requested
    end
  end

  describe ".kakugosearch" do
    it "returns AR records ordered by search rank" do
      art1 = Article.create!(title: "First",  body: "a", slug: "/1")
      art2 = Article.create!(title: "Second", body: "b", slug: "/2")

      stub_request(:get, /indexes\/articles\/search/)
        .to_return(
          status: 200,
          body: { hits: [{ id: art2.id.to_s }, { id: art1.id.to_s }] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      results = Article.kakugosearch("test")
      expect(results.map(&:id)).to eq([art2.id, art1.id])
    end

    it "returns empty array when no hits" do
      stub_request(:get, /search/).to_return(
        status: 200,
        body: '{"hits":[]}',
        headers: { "Content-Type" => "application/json" }
      )

      expect(Article.kakugosearch("nothing")).to eq([])
    end

    it "raises KakugoSearch::Error on search failure" do
      stub_request(:get, /search/).to_raise(SocketError.new("connection refused"))
      expect { Article.kakugosearch("boom") }.to raise_error(KakugoSearch::Error, /Search failed/)
    end
  end

  describe "indexing errors" do
    it "does not raise when indexing fails, logs instead" do
      stub_request(:post, /documents/).to_raise(SocketError.new("no connection"))

      expect {
        Article.create!(title: "Fails quietly", body: "x", slug: "/q")
      }.not_to raise_error
    end
  end
end
