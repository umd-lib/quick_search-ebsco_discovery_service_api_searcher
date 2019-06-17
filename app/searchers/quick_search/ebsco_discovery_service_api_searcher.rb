# frozen_string_literal: true

module QuickSearch
  # QuickSearch seacher for EBSCO Discovery Service
  class EbscoDiscoveryServiceApiSearcher < QuickSearch::Searcher
    def session
      return @eds_session if @eds_session
      # Get the configuration values
      username = get_config('username')
      password = get_config('password')
      @eds_session = EBSCO::EDS::Session.new(user: username, pass: password, profile: 'edsapi', guest: false)
      @eds_session
    end

    def search
      @response = session.search(query_params)
    end

    def results # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      return results_list[0..@per_page - 1] if results_list
      @results_list = []
      @response.records.each do |record|
        result = OpenStruct.new
        result.title = record.eds_title
        result.link = item_link(record)
        result.author = record.eds_authors.join
        result.date = record.eds_publication_date
        result.item_format = item_format(record)
        @results_list << result
      end
      @results_list[0..@per_page - 1]
    end

    # Returns the item format for the given record. Using a method so
    # it can be overridden by subclasses.
    def item_format(record)
      EbscoItemFormats.item_format(record)
    end

    def total
      @response.stat_total_hits
    end

    def query_params
      {
        query: sanitized_user_search_query,
        results_per_page: items_per_page
      }
    end

    def loaded_link
      get_config('loaded_link') + percent_encoded_raw_user_search_query
    end

    def item_link(record)
      get_config('url_link') + '&db=' + record.eds_database_id + '&AN=' + record.eds_accession_number
    end

    # Returns the percent-encoded search query entered by the user, skipping
    # the default QuickSearch query filtering
    def percent_encoded_raw_user_search_query
      CGI.escape(@q)
    end

    # Returns the sanitized search query entered by the user, skipping
    # the default QuickSearch query filtering
    def sanitized_user_search_query
      # Need to use "to_str" as otherwise Japanese text isn't returned
      # properly
      sanitize(@q).to_str
    end

    def items_per_page
      allowed_values = [10, 25, 50, 100]
      allowed_values.each do |val|
        return val if @per_page <= val
      end
      allowed_values.last
    end

    def get_config(key)
      QuickSearch::Engine::EBSCO_DISCOVERY_SERVICE_API_CONFIG[key]
    end
  end

  # Provides a mapping of EBSCO publication_type_ids to UMD types
  class EbscoItemFormats
    # Map of EBSCO publication_types ids to UMD format, i.e.
    # EBSCO => UMD
    @item_formats = {
      'academicJournal' => 'article',
      'audio' => 'audio',
      'book' => 'book',
      'ebook' => 'e_book',
      'image' => 'image',
      'journal' => 'journal',
      'serialPeriodical' => 'journal',
      'map' => 'map',
      'score' => 'score',
      'dissertation' => 'thesis',
      'videoRecording' => 'video_recording'
    }.transform_keys(&:downcase)

    # Returns string representing the item format for the given record
    def self.item_format(record)
      item_format = @item_formats[record.eds_publication_type_id.downcase]

      # Return either the item_format or default_format
      default_format = 'other'
      item_format || default_format
    end
  end
end
