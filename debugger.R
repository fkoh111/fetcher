library("rtweet")

account <- "tommyannfeldt"
followers <- get_followers(account)
mapply(write.table, x = followers, row.names = FALSE, col.names = FALSE, file = paste(names(followers), "csv", sep = "."))
listed_ids <- list.files(pattern = "user_id.csv", full.names = TRUE)
read_ids <- lapply(listed_ids, read_twitter_csv)
test <- lapply(read_ids, lookup_users)