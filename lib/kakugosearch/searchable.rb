require "active_support/concern"

module KakugoSearch
  module Searchable
    extend ActiveSupport::Concern

    included do
      class_attribute :_kakugosearch_index_name, instance_writer: false
      class_attribute :_kakugosearch_fields,      instance_writer: false
    end

    class_methods do
      # kakugosearch_index index: "articles", fields: { title: :title, body: :content }
      def kakugosearch_index(index: nil, fields: {})
        self._kakugosearch_index_name = index || table_name
        self._kakugosearch_fields     = fields

        after_save    :kakugosearch_index_document
        after_destroy :kakugosearch_delete_document
      end

      # Article.kakugosearch("rust programming", limit: 10, ai: false)
      def kakugosearch(query, limit: 20, ai: false, ai_weight: 0.3)
        result = KakugoSearch.client.search(
          _kakugosearch_index_name, query,
          limit: limit, ai: ai, ai_weight: ai_weight
        )

        hits = Array(result["hits"])
        ids  = hits.map { |h| h["id"] }
        return none if ids.empty?

        # Preserve ranked order
        records_by_id = where(id: ids).index_by { |r| r.id.to_s }
        ids.filter_map { |id| records_by_id[id.to_s] }
      rescue => e
        raise KakugoSearch::Error, "Search failed: #{e.message}"
      end
    end

    private

    def kakugosearch_index_document
      doc = { id: id.to_s }
      self.class._kakugosearch_fields.each do |field, method_name|
        doc[field] = public_send(method_name)
      end
      KakugoSearch.client.index_documents(self.class._kakugosearch_index_name, [doc])
    rescue => e
      logger = defined?(Rails) ? Rails.logger : Logger.new($stderr)
      logger.error("[KakugoSearch] Failed to index #{self.class.name}##{id}: #{e.message}")
    end

    def kakugosearch_delete_document
      KakugoSearch.client.delete_document(self.class._kakugosearch_index_name, id.to_s)
    rescue => e
      logger = defined?(Rails) ? Rails.logger : Logger.new($stderr)
      logger.error("[KakugoSearch] Failed to delete #{self.class.name}##{id}: #{e.message}")
    end
  end
end
