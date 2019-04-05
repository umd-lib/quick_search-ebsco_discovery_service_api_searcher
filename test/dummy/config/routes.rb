Rails.application.routes.draw do
  mount QuickSearchEbscoDiscoveryServiceApiSearcher::Engine => "/quick_search-ebsco_discovery_service_api_searcher"
end
