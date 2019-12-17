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
        Rails.logger.debug(
          'QuickSearch::EbscoDiscoveryServiceApiArticleSearcher.item_link - DOI link found. Returning.'
        )
        return get_config('doi_link') + record.eds_document_doi
      end

      # Return link WorldCat OpenUrl link resolver, if available
      link_from_open_url = link_from_open_url(record)
      if link_from_open_url
        Rails.logger.debug(
          'QuickSearch::EbscoDiscoveryServiceApiArticleSearcher.item_link - OpenURL link found. Returning.'
        )
        return link_from_open_url
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
      links = UmdOpenUrl::Resolver.parse_response(json)

      return nil if links.nil? || links.size.zero?

      if links.size == 1
        Rails.logger.debug(
          'QuickSearch::EbscoDiscoveryServiceApiArticleSearcher.link_from_open_url - '\
          'Single OpenURL resolved link found. Returning.'
        )
        return links[0]
      else
        Rails.logger.debug(
          'QuickSearch::EbscoDiscoveryServiceApiArticleSearcher.link_from_open_url - '\
          "#{links.size} OpenURL resolved links found. Returning link to citation finder"
        )
        open_url_link_uri = URI.parse(open_url_link)
        params_map = CGI.parse(open_url_link_uri.query)
        filtered_params_map = params_map.reject { |k, _v| k == 'wskey' }

        # Regenerate the query parameters string. Using Rack::Utils.build_query
        # because it produces a query string without array-based parameters
        filtered_params = Rack::Utils.build_query(filtered_params_map)

        filtered_params = nil if filtered_params.strip.empty?

        # Construct the link to the resource
        citiation_finder_uri = URI::HTTP.build(
          host: 'umaryland.on.worldcat.org',
          path: '/atoztitles/link',
          query: filtered_params
        )
        citiation_finder_uri.scheme = 'https'
        citiation_finder_url = citiation_finder_uri.to_s
        citiation_finder_url
      end
    end

    def open_url_resolve_link(record) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      issn = record.eds_issns&.first
      volume = record.eds_volume
      issue_number = record.eds_issue
      page_start = record.eds_page_start
      date_published = record.eds_publication_date

      Rails.logger.debug do
        <<~LOGGER_END
          QuickSearch::EbscoDiscoveryServiceApiArticleSearcher.open_url_resolve_link
          \tissn: #{issn}
          \tvolume: #{volume}
          \tissue_number: #{issue_number}
          \tpage_start: #{page_start}
          \tdate_published: #{date_published}
        LOGGER_END
      end

      # Return nil if the necessary parameters weren't found.
      unless issn && volume && issue_number && page_start && date_published
        Rails.logger.debug do
          'QuickSearch::EbscoDiscoveryServiceApiArticleSearcher.open_url_resolve_link data missing. Returning nil'
        end

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
