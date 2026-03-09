# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**kakugosearch-rails** — a Ruby gem that integrates [KakugoSearch](../kakugosearch) into Rails apps via an ActiveRecord concern. Records are indexed/deleted synchronously on save/destroy, and a `.kakugosearch` class method provides ranked search results.

## Commands

```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/kakugosearch/client_spec.rb

# Run a single example by line number
bundle exec rspec spec/kakugosearch/searchable_spec.rb:42
```

## Testing Policy

- Always run `bundle exec rspec` after changing functionality to confirm nothing is broken.
- Always add tests when adding new functionality. No new public method or behaviour should ship without a corresponding spec.
- Tests must pass with **0 failures** before a change is considered done.
- Use WebMock to stub all HTTP calls — specs must never make real network requests.
- Keep the in-memory SQLite setup in `spec/spec_helper.rb`; add columns there if new AR attributes are needed by tests.

## Validation Checklist

Run these checks before marking any task complete:

```bash
# 1. All specs pass
bundle exec rspec

# 2. No unexpected network calls leak through (WebMock will raise if they do)
# — covered automatically by the rspec run above

# 3. Gem loads cleanly
ruby -e "require 'kakugosearch'; puts KakugoSearch::VERSION"
```

Expected output for a healthy state:

```
X examples, 0 failures
```

If any failures appear, fix them and re-run before finishing.

## Adding New Functionality

Follow this sequence for every change:

1. **Write the spec first** (or alongside the code) in the appropriate file:
   - HTTP client behaviour → `spec/kakugosearch/client_spec.rb`
   - ActiveRecord concern behaviour → `spec/kakugosearch/searchable_spec.rb`
   - New module → create `spec/kakugosearch/<module>_spec.rb` and `require` it from `spec_helper.rb`
2. Implement the feature.
3. Run `bundle exec rspec` — all examples must be green.
4. If the new feature touches the public API, update `README.md`.

## Source File Layout

```
lib/
├── kakugosearch.rb                # Entry point: configure, client, reset!
└── kakugosearch/
    ├── version.rb                 # VERSION constant
    ├── configuration.rb           # KakugoSearch::Configuration (url, api_key, default_index)
    ├── client.rb                  # Net::HTTP wrapper: index_documents, delete_document, search
    ├── searchable.rb              # ActiveRecord concern + kakugosearch_index DSL
    └── railtie.rb                 # Auto-loads concern when Rails is present

spec/
├── spec_helper.rb                 # WebMock + in-memory SQLite AR setup
└── kakugosearch/
    ├── client_spec.rb
    └── searchable_spec.rb
```

## Architecture

- **`KakugoSearch::Client`** — thin `net/http` + `json` wrapper, no extra runtime dependencies.
- **`KakugoSearch::Searchable`** — `ActiveSupport::Concern` that adds `after_save` / `after_destroy` callbacks and a `.kakugosearch` class method. Indexing errors are rescued and logged (so saves never fail); search errors raise `KakugoSearch::Error`.
- **`KakugoSearch::Railtie`** — loads the concern automatically when Rails is present.

## Configuration

```ruby
KakugoSearch.configure do |c|
  c.url     = "http://localhost:7700"        # required
  c.api_key = ENV["KAKUGOSEARCH_AI_API_KEY"] # optional
end
```

Call `KakugoSearch.reset!` in tests to clear memoized config and client between examples.

## Key Design Decisions

- **Synchronous callbacks** — indexing fires inline with `save`/`destroy`. Callers can switch to `after_commit` if post-transaction indexing is preferred.
- **No extra runtime deps** — only `railties` is a runtime dependency; everything else is stdlib.
- **Search returns AR records** in ranked order via `Model.where(id: ids)` + manual re-ordering.
- **Index name** defaults to `table_name` if not specified in `kakugosearch_index`.
