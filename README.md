# kakugosearch-rails

Rails integration for [KakugoSearch](https://github.com/your-org/kakugosearch) — a lightweight, AI-enhanced full-text search engine written in Rust.

## Installation

Add to your `Gemfile`:

```ruby
gem "kakugosearch-rails"
```

Then run:

```bash
bundle install
```

## Configuration

```ruby
# config/initializers/kakugosearch.rb
KakugoSearch.configure do |config|
  config.url     = "http://localhost:7700"          # KakugoSearch server URL
  config.api_key = ENV["KAKUGOSEARCH_AI_API_KEY"]   # optional, for AI reranking
end
```

## Usage

Include `KakugoSearch::Searchable` in any ActiveRecord model and declare which fields to index:

```ruby
class Article < ApplicationRecord
  include KakugoSearch::Searchable

  kakugosearch_index(
    index:  "articles",          # index name (defaults to table_name)
    fields: {
      title: :title,             # KakugoSearch field => AR attribute/method
      body:  :content,
      url:   :permalink,
    }
  )
end
```

Records are automatically indexed on `save` and removed from the index on `destroy`.

### Searching

```ruby
# Basic search
results = Article.kakugosearch("rust programming")

# With options
results = Article.kakugosearch("machine learning",
  limit:     10,
  ai:        true,    # enable AI reranking
  ai_weight: 0.5      # blend of BM25 vs AI (0.0–1.0)
)
```

Returns ActiveRecord objects in ranked order.

## Behaviour Notes

- **Synchronous** — indexing happens inline with `save`/`destroy`. Wrap in `after_commit` if you need post-transaction indexing.
- **Errors on indexing are logged, not raised** — a failed HTTP call to KakugoSearch will not break your model save.
- **Errors on search do raise** — a `KakugoSearch::Error` is raised so callers can handle it.

## Development

```bash
bundle install
bundle exec rspec
```

## License

MIT
