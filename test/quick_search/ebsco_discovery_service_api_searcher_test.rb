# frozen_string_literal: true

require 'test_helper'

module QuickSearch
  class EbscoDiscoveryServiceApiSearcher
    # DatabaseFinderSearch tests
    class Test < ActiveSupport::TestCase
      test 'truth' do
        assert_kind_of Module, QuickSearch::EbscoDiscoveryServiceApiSearcher
      end
    end
  end
end
