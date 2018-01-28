##############################################################################
# FETCHER (v. 0.9.5)                                                         #
# A UDF for the rtweet package making it easy for R users to                 #
# fetch followers' user data from Twitter accounts without having to worry   #
# about rate limits and users with more than 90.000 followers.               #
# Use fetcher as any of the original rtweet functions.                       #
# For further information see github: https://github.com/fkoh111/fetcher     #
##############################################################################


# fetcher() takes two arguments: user = a Twitter username or a user id. path = a path to a chosen output folder for temporary files (path argument is optional)
fetcher <- function(user, verbose = TRUE, path = NULL){

# Setting tmp_path and folder for follower ids. On exit the directory will be reset
root <- getwd()
if (!is.null(path)) {
  tmp_path <- tempfile(pattern = user, tmpdir = path)
} else {
  tmp_path <- tempfile(pattern = user, tmpdir = tempdir())
}
dir.create(tmp_path)
setwd(tmp_path)

# Fetching followers count
n_follower_ids <- lookup_users(user)$followers_count

# Initializing parameters
param_sleep <- 900
param_users <- 90000
trunc_follower_ids <- sum(trunc(n_follower_ids / param_users) * param_sleep)
follower_ids_estimate <- format(Sys.time() + trunc_follower_ids, format = '%H:%M:%S')

if (verbose == TRUE) {
  message("Starting to fetch ", paste(n_follower_ids), " follower IDs. Expects to be done at ", paste(follower_ids_estimate), ".")
} else {
  NULL
}
  
# Fetching follower ids; if rate limit is encountered: sleep for 15 minutes
follower_ids <- get_followers(user, n = as.integer(n_follower_ids), parse = TRUE, retryonratelimit = TRUE, verbose = FALSE)

# Spliting follower_ids into n chunk_follower_ids with max size of of 90.000 Twitter ids
chunk_follower_ids <- split(follower_ids, (seq(nrow(follower_ids)) - 1) %/% param_users)

# Writing chunk_follower_ids to tmp_path
mapply(write.table, x = chunk_follower_ids, row.names = FALSE, col.names = FALSE, file = paste(names(chunk_follower_ids), "txt", sep = "."))

# Listing and reading chunk_follower_ids from tmp_path
filenames <- list.files(path = tmp_path, pattern = "*.txt", full.names = TRUE)
ids <- lapply(filenames, read.table)

# Estimating and printing when the lookup_users process will be done
if (verbose == TRUE) {
  if (length(filenames) > 1) {
    users_estimate <- format(Sys.time() + length(filenames) * param_sleep, format = '%H:%M:%S')
    message("Starting to look up users. Expects to be done at ", paste(users_estimate), ".")  
  } else {
  NULL
  }
} else {
NULL
}

# From chunk_follower_ids user data is fetched. Rate limit is avoided by sleeping after each chunk_follower_ids have been looked up
followers <- rep(NA, length(filenames))
if (length(filenames) > 1)
  for (i in seq_along(ids)) {
  followers[i] <- lapply(ids[i], lookup_users)
  if (i > length(filenames) - 1){
    break
  }
  if (verbose == TRUE) {
  sleep_estimate <- format(Sys.time() + param_sleep, format = '%H:%M:%S')
  message("Avoiding rate limit by sleeping for 15 minutes. Will start again at approximately ", paste(sleep_estimate), ".")
  } else {
    NULL
    }
  Sys.sleep (param_sleep)
  } else {
    for (i in seq_along(ids)) {
    followers[i] <- lapply(ids[i], lookup_users)
    }
  }

# Binding followers user data
binded_followers <- do_call_rbind(followers)

# Clean up
on.exit(setwd(root), add = TRUE)
message("Jobs done at ", paste(format(Sys.time(), format = '%H:%M:%S')), ".")

return(binded_followers)
}

# Function usage
fetched_followers <- fetcher(user = "fkoh111", path =  "~/Desktop/", verbose = FALSE)
