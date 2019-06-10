# frozen_string_literal: true

module QuickSearch
  # QuickSearch seacher for WorldCat
  class EbscoDiscoveryServiceApiArticleSearcher < EbscoDiscoveryServiceApiSearcher
    def query_params
      article_filter = { 'eds_publication_type_facet' => ['Academic Journals'] }
      {
        query: sanitized_user_search_query,
        results_per_page: items_per_page,
        'f' => article_filter
      }
    end

    def item_link(record)
      return get_config('doi_link') + record.eds_document_doi if record.eds_document_doi
      get_config('url_link') + '&db=' + record.eds_database_id + '&AN=' + record.eds_accession_number
    end

    def items_per_page
      allowed_values = [10, 25, 50, 100]
      allowed_values.each do |val|
        return val if @per_page <= val
      end
      allowed_values.last
    end

    def get_config(key)
      QuickSearch::Engine::EBSCO_DISCOVERY_SERVICE_API_ARTICLE_CONFIG[key]
    end
  end
end
