
fetcher <- function(user, verbose = TRUE, path = NULL){
# Fetches Twitter followers data from accounts having more than 90.000
# followers whilst dealing with rate limits in an automated manner.
#
# Args:
#  user: takes a Twitter username or a user id.
#  path: takes a path to a chosen output folder for temporary files (optional).
#  verbose: takes a boolean. If verbose is set to false time estimates will
#  not be printed during runtime (defaults to true).
#
# Returns:
#  A data frame containing n observations of 20 Twitter variables where n equals 
#  the follower count of argument user.

   
  
  
# Setting a tmp folder for .txt files containing follower_ids.
# If path argument has been provided that path will be used for tmp folder location.
# If not the base R tempdir() function will be used to generate a tmp location.
# On exit the directory will be reset to the initial wd before calling fetcher().
root <- getwd()
if (!is.null(path)) {
  tmp_path <- tempfile(pattern = user, tmpdir = path)
} else {
  tmp_path <- tempfile(pattern = user, tmpdir = tempdir())
}
dir.create(tmp_path)
setwd(tmp_path)

# Fetching followers_count from argument user.
# Argument n users followers_count is being divided by 90.000, truncated and
# then multiplied by 900 sec (15 min).
# Thereby we're able to print primitive time estimates for the process during runtime.
# Parameters with suffix param_ is being used repeatedly in the script,
# therefore we're binding them to an object.
n_follower_ids <- lookup_users(user)$followers_count
param_sleep <- 900  # 900 sec used in conjunction with Sys.sleep() - 15 min.
param_users <- 90000  # 90.000 users (the max) for a lookup_users batch.
trunc_follower_time <- sum(trunc(n_follower_ids / param_users) * param_sleep)
follower_ids_estimate <- format(Sys.time() + trunc_follower_time, format = '%H:%M:%S')

if (verbose == TRUE) {  # Checking verbose boolean. If false message is null.
  message("Starting to fetch ", paste(n_follower_ids), " follower IDs. Expects to be done at ", paste(follower_ids_estimate), ".")
}

# Fetching argument users n_follower_ids. If rate limit is encountered: sleeping for 15 minutes.
follower_ids <- get_followers(user, n = as.integer(n_follower_ids), parse = TRUE, retryonratelimit = TRUE, verbose = FALSE)

# Spliting argument user n_follower_ids into chunk_follower_ids with a max size of 90.000 ids.
chunk_follower_ids <- split(follower_ids, (seq(nrow(follower_ids)) - 1) %/% param_users)

# Writing chunk_follower_ids as .txt files to tmp_path and its corresponding folder.
mapply(write.table, x = chunk_follower_ids, row.names = FALSE, col.names = FALSE, file = paste(names(chunk_follower_ids), "txt", sep = "."))

# Listing and reading chunk_follower_ids from tmp_path.
listed_ids <- list.files(path = tmp_path, pattern = "*.txt", full.names = TRUE)
read_ids <- lapply(listed_ids, read.table)

# Checking verboose boolean and whether there's more than one chunk of listed_ids in tmp_path.
# If true estimating and printing when lookup_users process will be done
if (verbose == TRUE & length(listed_ids) > 1) {
  users_estimate <- format(Sys.time() + length(listed_ids) * param_sleep, format = '%H:%M:%S')
  message("Starting to look up users. Expects to be done at ", paste(users_estimate), ".")  
}

# From listed_ids in tmp_path user data is being looked up as object followers.
# Rate limit is avoided by sleeping after each chunk of read_ids have been looked up.
# The last iteration will break when i is greater than the length of listed_ids -1.
# Thereby avoiding a Sys.sleep after the last lookup.
# If verbose is set to false time estimate will not be printed.
followers <- rep(NA, length(listed_ids))
  for (i in seq_along(read_ids)) {
  followers[i] <- lapply(read_ids[i], lookup_users)
    if (i > length(listed_ids) - 1) {
      break
    }
  if (verbose == TRUE) {
  sleep_estimate <- format(Sys.time() + param_sleep, format = '%H:%M:%S')
  message("Avoiding rate limit by sleeping for 15 minutes. Will start again at approximately ", paste(sleep_estimate), ".")
  } 
}

binded_followers <- do_call_rbind(followers)  # Binding followers into df.

on.exit(setwd(root), add = TRUE)  # Resetting to user wd.
if (verbose == TRUE) {  # Checking verboose boolean.
  message("Jobs done at ", paste(format(Sys.time(), format = '%H:%M:%S')), ".")
}

return(binded_followers)
}


# Function example.
library("rtweet")
fetched_followers <- fetcher(user = "tommyannfeldt", path =  "~/Desktop/", verbose = TRUE)
