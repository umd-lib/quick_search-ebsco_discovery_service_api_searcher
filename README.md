# quick_search-ebsco_discovery_service_api_searcher

EBSCO Discovery Service API searcher for NCSU Quick Search

## Installation

Include the searcher gem in your Gemfile:

```
gem 'quick_search-ebsco_discovery_service_api_searcher'
```

Run bundle install:

```
bundle install
```

This gem provides two separate EBSCO Discovery Service searchers:

*ebsco_discovery_service_api_searcher: A searcher that queries EBSCO Discovery Service
  for all item types
*ebsco_discovery_service_api_article_searcher: A searcher that limits the
  EBSCO Discovery Service query to articles and book chapters

The ebsco_discovery_service_api_article_searcher has special handling to return a
direct link to the article (instead of to the EBSCO catalog entry), where
possible.

## Searcher Configuration

### ebsco_discovery_service_api_searcher

In your search application:

1) Add the "ebsco_discovery_service_api" searcher to config/quick_search_config.yml

2) Copy the config/ebsco_discovery_service_api_config.yml file into the
   config/searchers/ directory and fill out the
   values are appropriate.

3) Include in your Search Results page

```
<%= render_module(@ebsco_discovery_service, 'ebsco_discovery_service_api') %>
```

### ebsco_discovery_service_api_article

1) Add the "ebsco_discovery_service_api_article" searcher to config/quick_search_config.yml

2) Copy the config/ebsco_discovery_service_api_article_config.yml file into the
   config/searchers/ directory and fill out the
   values are appropriate.

3) Include in your Search Results page

```
<%= render_module(@ebsco_discovery_service_article, 'ebsco_discovery_service_api_article') %>
```
