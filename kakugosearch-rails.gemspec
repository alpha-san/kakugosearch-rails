require_relative "lib/kakugosearch/version"

Gem::Specification.new do |spec|
  spec.name        = "kakugosearch-rails"
  spec.version     = KakugoSearch::VERSION
  spec.authors     = ["Allan Farinas"]
  spec.email       = ["hello@allanfarinas.com"]
  spec.homepage    = "https://github.com/alpha-san/kakugosearch-rails"
  spec.summary     = "Rails integration for the KakugoSearch AI-enhanced search engine"
  spec.description = "Drop-in ActiveRecord concern that keeps KakugoSearch indexes in sync " \
                     "with your models via save/destroy callbacks, plus a search class method."
  spec.license     = "MIT"

  spec.metadata = {
    "homepage_uri"    => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri"   => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues"
  }

  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE"]

  spec.add_dependency "railties", ">= 6.0"

  spec.add_development_dependency "rspec",        "~> 3.0"
  spec.add_development_dependency "webmock",      "~> 3.0"
  spec.add_development_dependency "activerecord", ">= 6.0"
  spec.add_development_dependency "sqlite3"
end
