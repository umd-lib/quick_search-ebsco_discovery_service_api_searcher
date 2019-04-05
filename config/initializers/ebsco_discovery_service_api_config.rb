# Try to load a local version of the config file if it exists - expected to be in quicksearch_root/config/searchers/<my_searcher_name>_config.yml

# Returns the value for the given key, first checking the EBSCO Discovery Service API
# config file, and then falling back to the EBSCO Discovery Service API Article
# configuration, if not found.
def get_common_configuration(key)
  QuickSearch::Engine::EBSCO_DISCOVERY_SERVICE_API_CONFIG[key] ||
  QuickSearch::Engine::EBSCO_DISCOVERY_SERVICE_API_ARTICLE_CONFIG[key]
end

# EBSCO Discovery Service API searcher configuration
if File.exists?(File.join(Rails.root, '/config/searchers/ebsco_discovery_service_api_config.yml'))
  config_file = File.join Rails.root, '/config/searchers/ebsco_discovery_service_api_config.yml'
else
  # otherwise load the default config file
  config_file = File.expand_path('../../ebsco_discovery_service_api_config.yml', __FILE__)
end
QuickSearch::Engine::EBSCO_DISCOVERY_SERVICE_API_CONFIG = YAML.load(ERB.new(File.read(config_file)).result)[Rails.env]

# EBSCO Discovery Service API Article searcher configuration
if File.exists?(File.join(Rails.root, '/config/searchers/ebsco_discovery_service_api_article_config.yml'))
  config_file = File.join Rails.root, '/config/searchers/ebsco_discovery_service_api_article_config.yml'
else
  # otherwise load the default config file
  config_file = File.expand_path('../../ebsco_discovery_service_api_article_config.yml', __FILE__)
end
QuickSearch::Engine::EBSCO_DISCOVERY_SERVICE_API_ARTICLE_CONFIG = YAML.load(ERB.new(File.read(config_file)).result)[Rails.env]

