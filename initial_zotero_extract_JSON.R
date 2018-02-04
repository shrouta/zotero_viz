## This script queries a user's Zotero library and pulls the recently added items, along with their collections.  Since the Zotero API has a limit of 25 items, use the zotero_extract_JSON_weekly script to update your JSON file
## Make sure to update Zotero user and API key

# Sets the date to start pulling.  Default is January 1, 2018
start_date <- as.Date("2018-01-01", tz="GMT")

# Loads Libraries
install.packages("jsonlite")
install.packages("d3r")
library("jsonlite", lib.loc="/Library/Frameworks/R.framework/Versions/3.4/Resources/library")
library("plyr", lib.loc="/Library/Frameworks/R.framework/Versions/3.4/Resources/library")
library("d3r", lib.loc="/Library/Frameworks/R.framework/Versions/3.4/Resources/library")

# Creates variable subsets
zotero_metadata <- c("meta.creatorSummary", "data.title", "data.publicationTitle", "data.volume", "data.issue", "data.pages", "data.date", "data.collections", "data.dateAdded")
json_metadata <- c("collection", "name", "size")
collections_metadata <- c("key", "data.name")

# Calls zotero collections, coerces them into a data frame and converts the collections key to a character string
collections <- fromJSON('https://api.zotero.org/users/XXXXXX/collections?key=XXXXXXXXX', flatten=TRUE)
collections <- as.data.frame(collections)
collections <- collections[collections_metadata]
collections$key <- as.character(collections$key)

# Calls most recent Zotero items, coerces them into a data frame, subsets useful variables and renames them
recent_zotero <- fromJSON('https://api.zotero.org/users/XXXXXX/items?format=json&itemType=journalArticle&key=XXXXXXXXXX', flatten=TRUE)
recent_zotero_data <- as.data.frame(recent_zotero)
recent_zotero_data <- recent_zotero_data[zotero_metadata]
recent_zotero_data <- rename(recent_zotero_data, c("meta.creatorSummary"="author", "data.title"="title", "data.publicationTitle"="publication", "data.volume"="volume", "data.issue"="issue", "data.pages"="pages", "data.date"="date", "data.collections"="collections", "data.dateAdded"="date_added"))

# Converts collections ID into character string
recent_zotero_data$collections <- as.character(recent_zotero_data$collections)

# Converts the date_added variable to date format, and includes only those items since last updated
recent_zotero_data$date_added <- as.Date(recent_zotero_data$date_added)
#recent_zotero_data <- subset(recent_zotero_data, date_added > last_updated)
recent_zotero_data <- subset(recent_zotero_data, date_added > start_date)

# Merges collections and zotero items, so that Zotero items have collection names and nicknames
recent_zotero_data <- merge(x=recent_zotero_data, y=collections, by.x="collections", by.y="key")
recent_zotero_data <- rename(recent_zotero_data, c("data.name"="collection"))

# Appends a variable for the full name of the reading, the size and the top-level category (for reading by d3.js)
recent_zotero_data$name <-apply(recent_zotero_data,1 ,function(x) paste0(toString(x[2]),toString(", "), toString(x[3]),toString(", in "), toString(x[4]), toString(" Vol. "),toString(x[5]), toString(" Issue "), toString(x[6]), toString(" pp. "), toString(x[7]), toString(" ("), toString(x[8]), toString(")")))
recent_zotero_data$size <- 1

# Subsets recent_zotero_data to include only the data required for d3.js, converts to JSON
recent_zotero_data <- recent_zotero_data[json_metadata]

# Writes new additions to a JSON file
JSON_export <- d3_nest(recent_zotero_data, value_cols="size", root="365 in 2018")
JSON_export <- prettify(JSON_export, indent=4)
con <- file("papers_2018.json")
writeLines(JSON_export, con)
close(con)
