##############################################################################
# FETCHER (v. 0.9.1)                                                         #
# A UDF for the rtweet package making it easy for R users to                 #
# fetch followers' user data from Twitter accounts without having to worry   #
# about rate limits and users with more than 90.000 followers.               #
# Use fetcher as any of the original rtweet functions.                       #
# For further information see github: https://github.com/fkoh111/fetcher     #
##############################################################################


# fetcher() takes one arguments: either a Twitter username or a user id
fetcher <- function (x) {

        
# Checking for package dependencies; downloading, installing and loading if necessary
dependencies <- function(z) {
  z <- as.character(match.call() [[2]])
  if (!require(z, character.only = TRUE)){
    install.packages(pkgs = z, repos = "http://cran.r-project.org")
    require(z, character.only = TRUE)
  }
}
dependencies("data.table")
dependencies("rtweet")


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


# Writing chunk_follower_ids to temporary folder
for (i in 1:length(chunk_follower_ids)) {
  write.table(chunk_follower_ids[i], row.names = FALSE, col.names = FALSE, file=paste0(names(chunk_follower_ids)[i], ".txt"))
}


# Listing and reading chunk_follower_ids from temporary folder
filenames <- list.files(path = tmp_path, pattern="*.txt", full.names = TRUE)
ids <- lapply(filenames, read.table)


# From chunk_follower_ids user data is being fetched. Rate limit is being avoided by sleeping after each chunk_follower_ids have been looked up
followers <- rep(NA, length(list.files()))
if(length(filenames) > 1)
  for (i in seq_along(ids)) {
    followers[i] <- lapply(ids[i], lookup_users)
    message("Avoiding rate limit by sleeping for 15 minutes at ", paste(format(Sys.time(), format = '%H:%M:%S')))
    Sys.sleep(15*60)
  } else {
    for (i in seq_along(ids)) {
      followers[i] <- lapply(ids[i], lookup_users)}}


# Binding followers user data into a data.table
binded_followers <- rbindlist(followers, fill = TRUE)


# Clean up: resetting the working directory, purging temporary folder and id chunks if y argument has not been supplied
setwd(root)
message("Jobs done at ", paste(format(Sys.time(), format = '%H:%M:%S')))

return(binded_followers)
}


# Function usage
fetched_followers <- fetcher("tommyannfeldt")
