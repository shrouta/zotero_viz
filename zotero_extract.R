## This script queries a user's Zotero library and pulls the recently added items, along with their collections.

# If this is the first time you are running this script this year, use set last_updated to the first of the year and all_zotero_items to an empty data frame:
last_updated <- as.Date("2018-01-01", tz="GMT")
all_zotero_data <- data.frame()

# Loads Libraries
install.packages("jsonlite")
install.packages("d3r")
library("jsonlite", lib.loc="/Library/Frameworks/R.framework/Versions/3.4/Resources/library")
library("plyr", lib.loc="/Library/Frameworks/R.framework/Versions/3.4/Resources/library")
library("d3r", lib.loc="/Library/Frameworks/R.framework/Versions/3.4/Resources/library")

# Creates variable subsets
zotero_metadata <- c("meta.creatorSummary", "data.title", "data.publicationTitle", "data.volume", "data.issue", "data.pages", "data.date", "data.collections", "data.dateAdded")
json_metadata <- c("collection_name", "name", "size")
collections_metadata <- c("key", "data.name")

# Calls zotero collections, coerces them into a data frame and converts the collections key to a character string
collections <- fromJSON('https://api.zotero.org/users/204149/collections?key=y1TEiauuTLBML7DhGS774EPZ', flatten=TRUE)
collections <- as.data.frame(collections)
collections <- collections[collections_metadata]
collections$key <- as.character(collections$key)
collections <- rename(collections, c("data.name"="collection_name"))
collections$ID <- collections$collection_name

# Calls most recent Zotero items, coerces them into a data frame, subsets useful variables and renames them
recent_zotero <- fromJSON('https://api.zotero.org/users/204149/items?format=json&itemType=journalArticle&key=y1TEiauuTLBML7DhGS774EPZ', flatten=TRUE)
recent_zotero_data <- as.data.frame(recent_zotero)
recent_zotero_data <- recent_zotero_data[zotero_metadata]
recent_zotero_data <- rename(recent_zotero_data, c("meta.creatorSummary"="author", "data.title"="title", "data.publicationTitle"="publication", "data.volume"="volume", "data.issue"="issue", "data.pages"="pages", "data.date"="date", "data.collections"="collections", "data.dateAdded"="date_added"))

# Converts collections ID into character string
recent_zotero_data$collections <- as.character(recent_zotero_data$collections)

# Converts the date_added variable to date format, and includes only those items since last updated
recent_zotero_data$date_added <- as.Date(recent_zotero_data$date_added)
recent_zotero_data <- subset(recent_zotero_data, date_added > last_updated)

# Merges collections and zotero items, so that Zotero items have collection names and nicknames
recent_zotero_data <- merge(x=recent_zotero_data, y=collections, by.x="collections", by.y="key")
#recent_zotero_data <- rename(recent_zotero_data, c("ID"="collection"))

# Appends a variable for the full name of the reading and the size (for reading by d3.js)
recent_zotero_data$name <-apply(recent_zotero_data,1 ,function(x) paste0(toString(x[2]),toString(", "), toString(x[3]),toString(", in "), toString(x[4]), toString(" Vol. "),toString(x[5]), toString(" Issue "), toString(x[6]), toString(" pp. "), toString(x[7]), toString(" ("), toString(x[8]), toString(")")))
recent_zotero_data$size <- 1

# Culls the variables to those necessary for d3.js and adds an index variable.
recent_zotero_data <- recent_zotero_data[json_metadata]

# Lumps the new data in with the old data
all_zotero_data <- rbind(all_zotero_data, recent_zotero_data)

# Writes new additions to a JSON file
JSON_export <- d3_nest(all_zotero_data, value_cols="size", root="365 in 2018")
JSON_export <- prettify(JSON_export, indent=4)
con <- file("papers_2018.json")
writeLines(JSON_export, con)
close(con)

# Sets last updated
last_updated <- Sys.Date()
