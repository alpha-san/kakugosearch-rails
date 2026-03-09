require "webmock/rspec"
require "active_record"
require "kakugosearch"
require "kakugosearch/searchable"

# In-memory SQLite for AR model tests
ActiveRecord::Base.establish_connection(
  adapter:  "sqlite3",
  database: ":memory:"
)

ActiveRecord::Schema.define do
  create_table :articles, force: true do |t|
    t.string  :title
    t.text    :body
    t.string  :slug
    t.timestamps null: false
  end
end

class Article < ActiveRecord::Base
  include KakugoSearch::Searchable

  kakugosearch_index(
    index:  "articles",
    fields: {
      title: :title,
      body:  :body,
      url:   :slug,
    }
  )
end

RSpec.configure do |config|
  config.before(:each) do
    KakugoSearch.reset!
    WebMock.reset!
  end
end
