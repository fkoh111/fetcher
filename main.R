##############################################################################
# FETCHER (v. 0.9.2)                                                         #
# A UDF for the rtweet package making it easy for R users to                 #
# fetch followers' user data from Twitter accounts without having to worry   #
# about rate limits and users with more than 90.000 followers.               #
# Use fetcher as any of the original rtweet functions.                       #
# For further information see github: https://github.com/fkoh111/fetcher     #
##############################################################################


# fetcher() takes one arguments: either a Twitter username or a user id
fetcher <- function (x) {


# Setting a temporary folder for follower ids. On exit the directory will be reset
root <- getwd()
tmp_path <- tempfile(pattern = x, tmpdir = tempdir())
dir.create(tmp_path)
setwd(tmp_path)


# Fetching follower ids; if rate limit is encountered: sleep for 15 minutes
n_follower_ids <- (lookup_users(x)$followers_count)
message("Starting to fetch ", paste(n_follower_ids), " follower IDs at ", paste(format(Sys.time(), format = '%H:%M:%S')))
follower_ids <- get_followers(x, n = as.integer(n_follower_ids), parse = TRUE, retryonratelimit = TRUE, verbose = FALSE)


# Spliting follower_ids into n chunk_follower_ids, each chunk containing a maximum of 90.000 Twitter ids
chunk_follower_ids <- split(follower_ids, (seq(nrow(follower_ids))-1) %/% 90000)


# Writing chunk_follower_ids to temp_path
mapply(
  write.table,
  x = chunk_follower_ids, row.names = FALSE, col.names = FALSE, file=paste(names(chunk_follower_ids), "txt", sep=".")
)


# Listing and reading chunk_follower_ids from temp_path
filenames <- list.files(path = tmp_path, pattern="*.txt", full.names = TRUE)
ids <- lapply(filenames, read.table)


# From chunk_follower_ids user data is fetched. Rate limit is avoided by sleeping after each chunk_follower_ids have been looked up
if(length(filenames) > 1) {
  followers <- lapply(ids, lookup_users)
  message("Avoiding rate limit by sleeping for 15 minutes at ", paste(format(Sys.time(), format = '%H:%M:%S')))
  Sys.sleep(15*60)
  } else {
  followers <- lapply(ids, lookup_users)}


# Binding followers user data via data.table
binded_followers <- do_call_rbind(followers)


# Clean up
on.exit(setwd(root), add = TRUE)
message("Jobs done at ", paste(format(Sys.time(), format = '%H:%M:%S')))

return(binded_followers)
}


# Function usage
fetched_followers <- fetcher("mkrasnik")
