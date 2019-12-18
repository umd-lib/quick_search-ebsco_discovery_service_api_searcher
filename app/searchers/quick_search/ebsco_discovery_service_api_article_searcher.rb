# frozen_string_literal: true

require 'umd_open_url'

module QuickSearch
  # QuickSearch seacher for EBSCO Discovery Service (Articles)
  class EbscoDiscoveryServiceApiArticleSearcher < EbscoDiscoveryServiceApiSearcher
    def query_params
      article_filter = { 'eds_publication_type_facet' => ['Academic Journals'] }
      {
        query: sanitized_user_search_query,
        results_per_page: items_per_page,
        'f' => article_filter
      }
    end

    # Returns the link to use for the given item.
    def item_link(record)
      doi_link = doi_generator(record)

      # Return DOI link, in one exists
      return doi_link if doi_link

      # Query OpenURL resolve service for results
      open_url_links = open_url_generator(record)
      if open_url_links.size.positive?
        # If there is only one result, return it
        return open_url_links[0] if open_url_links.size == 1

        # If there are multiple results, return a "Citation Finder" link
        return citation_generator(record)
      end

      # Default -- return link to the catalog detail page
      catalog_generator(record)
    end

    # Returns a single URL representing the link to the DOI, or nil if
    # no DOI is available
    def doi_generator(record)
      record.eds_document_doi
    end

    # Returns a list of URLs returned by an OpenURL resolver server, or an
    # empty list if no URLs are found.
    def open_url_generator(record)
      open_url_link = open_url_resolve_link(record)
      links = UmdOpenUrl::Resolver.resolve(open_url_link)
      links
    end

    # Returns a URL to a citation finder server, or nil if no citation
    # finder is available
    def citation_generator(record)
      builder = open_url_builder(
        record, QuickSearch::Engine::EBSCO_DISCOVERY_SERVICE_API_ARTICLE_CONFIG['citation_finder_link']
      )
      builder&.build
    end

    def catalog_generator(record)
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

    # Returns an OpenUrlBuilder populated with information from the given
    # record and link
    def open_url_builder(record, link)
      builder = UmdOpenUrl::Builder.new(link)
      builder.issn(record.eds_issns&.first)
             .volume(record.eds_volume)
             .issue(record.eds_issue)
             .start_page(record.eds_page_start)
             .publication_date(record.eds_publication_date)

      builder
    end

    def open_url_resolve_link(record)
      open_url_resolver_service_link =
        QuickSearch::Engine::EBSCO_DISCOVERY_SERVICE_API_ARTICLE_CONFIG['open_url_resolver_service_link']
      builder = open_url_builder(record, open_url_resolver_service_link)
      return nil unless builder

      open_url_wskey = QuickSearch::Engine::EBSCO_DISCOVERY_SERVICE_API_ARTICLE_CONFIG['world_cat_open_url_wskey']
      builder.custom_param('wskey', open_url_wskey)

      return nil unless builder.valid?(%i[wskey issn volume issue start_page publication_date])

      builder.build
    end
  end
end
