require "rails/railtie"

module KakugoSearch
  class Railtie < Rails::Railtie
    initializer "kakugosearch.include_searchable" do
      ActiveSupport.on_load(:active_record) do
        # Searchable is opt-in; Railtie just ensures it's available without
        # manual require in application code.
        require "kakugosearch/searchable"
      end
    end
  end
end
