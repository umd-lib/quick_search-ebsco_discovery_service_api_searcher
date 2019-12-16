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

    def item_link(record) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      if record.eds_document_doi
        Rails.logger.debug('QuickSearch::EbscoDiscoveryServiceApiArticleSearcher.item_link - DOI link found. Returning.')
        return get_config('doi_link') + record.eds_document_doi
      end

      # Return link WorldCat OpenUrl link resolver, if available
      open_url_link = link_from_open_url(record)
      if open_url_link
        Rails.logger.debug('QuickSearch::EbscoDiscoveryServiceApiArticleSearcher.item_link - OpenURL link found. Returning.')
        return open_url_link if open_url_link
      end

      # Otherwise just return link to catalog detail page
      Rails.logger.debug('QuickSearch::EbscoDiscoveryServiceApiArticleSearcher.item_link - Defaulting to catalog detail link.')
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

    def link_from_open_url(record)
      # Generate the link to the WorldCat OpenUrl Resolver
      open_url_link = open_url_resolve_link(record)
      json = UmdOpenUrl::Resolver.resolve(open_url_link)
      link = UmdOpenUrl::Resolver.parse_response(json)

      link
    end

    def open_url_resolve_link(record) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      issn = record.eds_issns&.first
      volume = record.eds_volume
      issue_number = record.eds_issue
      page_start = record.eds_page_start
      date_published = record.eds_publication_date

      # Return nil if the necessary parameters weren't found.
      unless issn && volume && issue_number && page_start && date_published
        Rails.logger.debug{
          <<~LOGGER_END
            QuickSearch::EbscoDiscoveryServiceApiArticleSearcher.open_url_resolve_link data missing -
            \tissn: #{issn}
            \tvolume: #{volume}
            \tissue_number: #{issue_number}
            \tpage_start: #{page_start}
            \tdate_published: #{date_published}
          LOGGER_END
        }
        return nil
      end

      open_url_resolver_service_link =
        QuickSearch::Engine::EBSCO_DISCOVERY_SERVICE_API_ARTICLE_CONFIG['open_url_resolver_service_link']
      open_url_wskey = QuickSearch::Engine::EBSCO_DISCOVERY_SERVICE_API_ARTICLE_CONFIG['world_cat_open_url_wskey']

      b = UmdOpenUrl::Builder.new(open_url_resolver_service_link)
      b.custom_param('wskey', open_url_wskey).issn(issn).volume(volume)
       .issue(issue_number).start_page(page_start).publication_date(date_published)

      url = b.build

      url
    end
  end
end
