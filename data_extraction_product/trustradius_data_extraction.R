library(tidyverse)

file <- list.files("data", "json", full.names = TRUE)
page <- map(file, ~jsonlite::fromJSON(.x))
page <- map(page, ~{ .x$response$hits[[4]] %>% as_tibble() })

product <- map_df(page, ~{
  .x %>% 
    select(name, slug, homepage, vendor) %>%
    unnest(cols = c(vendor), names_repair = "universal", names_sep = "_") %>%
    select(-4)
})

pricing <- map_df(page, ~{
  .x %>% 
    select(name, slug, hasPricing, editionPricing) %>% 
    unnest(cols = c(editionPricing), names_repair = "universal", names_sep = "_") %>% 
    unnest(cols = c(editionPricing_deploymentTypes), names_repair = "universal", names_sep = "_")
})
names(pricing) <- c("name", "slug", "has_pricing",
                    "pricing_edition", "pricing_deploy",
                    "price", "terms")

features <- map_df(page, ~{
  .x %>% 
    select(name, slug, features) %>% 
    mutate(features = as.character(features),
           features = str_remove_all(features, '\"'),
           features = str_replace(features, "list\\(\\)", NA_character_),
           features = str_replace(features, "character\\(0\\)", NA_character_),
           features = str_replace(features, "NULL", NA_character_),
           features = str_remove(features, "c\\("),
           features = str_remove(features, "\\)"))
})

integration <- map_df(page, ~{
  .x %>% 
    select(name, slug, integrations) %>% 
    unnest(cols = c(integrations), names_repair = "universal", names_sep = "_") %>% 
    select(-3) %>% 
    rename(integration_with = integrations_name)
})

categories <- map_df(page, ~{
  .x %>% 
    select(name, slug, categories) %>% 
    unnest(cols = c(categories), names_repair = "universal", names_sep = "_") %>% 
    select(-3)
})

software <- integration %>% 
  filter(str_detect(tolower(integration_with), "github") |
           str_detect(tolower(integration_with), "sheets") |
           str_detect(tolower(integration_with), "analytics") |
           str_detect(tolower(integration_with), "hubspot") |
           str_detect(tolower(integration_with), "sql")) %>% 
  select(name) %>% 
  distinct() %>% 
  .[[1]]

pricing %>% 
  filter(name %in% software) %>% 
  select(name, pricing_edition, price, terms)

integration %>% 
  filter(name == "Mailparser") %>% 
  select(integration_with) %>% 
  .[[1]]

product %>% 
  filter(name == "Mailparser") %>% 
  select(homepage) %>% 
  .[[1]]

if (!dir.exists("output")) dir.create("output")
save(
  list = c("product", "pricing", "integration", "features", "categories"),
  file = "output/trustradius_data_extraction.RData")

