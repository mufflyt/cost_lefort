source("R/cms_sacrocolpopexy.R")

config_tbl <- read_cms_file_config("config/cms_files.csv")
missing_paths <- config_tbl$file_path[!file.exists(config_tbl$file_path)]

if (length(missing_paths) > 0) {
  message("Missing CMS files:")
  writeLines(missing_paths)
  quit(status = 1)
}

message("All configured CMS files exist.")
