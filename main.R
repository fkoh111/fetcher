##############################################################################
# FETCHER (v. 0.9.5)                                                         #
# A UDF for the rtweet package making it easy for R users to                 #
# fetch followers' user data from Twitter accounts without having to worry   #
# about rate limits and users with more than 90.000 followers.               #
# Use fetcher as any of the original rtweet functions.                       #
# For further information see github: https://github.com/fkoh111/fetcher     #
##############################################################################


# Fetcher() takes three arguments: user = a Twitter username or a user id. Path = a path to a chosen output folder for temporary files (argument path is optional). Verbose = argument defaults to TRUE meaning time estimates will be printed during runtime. If set to false, no messages will be printed.
fetcher <- function(user, verbose = TRUE, path = NULL){


## Setting a tmp folder for txt files containing user ids.
## If path argument has been provided that path will be used for tmp folder location.
## If not the base R tempdir() function will be used to supply location.
## On exit the directory will be reset to user specific wd.
root <- getwd()
if (!is.null(path)) {
  tmp_path <- tempfile(pattern = user, tmpdir = path)
} else {
  tmp_path <- tempfile(pattern = user, tmpdir = tempdir())
}
dir.create(tmp_path)
setwd(tmp_path)


## param_sleep: 900 sec used for Sys.sleep() - 15 min.
## param_users: 90.000 users (the max) for a lookup users batch.
## Fetching followers count from argument user.
## Argument users followers count is being divided by 90.000, truncated and then multiplied by 900 sec (15 min).
## Thereby we're able to print time estimates for the process during runtime. 
param_sleep <- 900
param_users <- 90000

n_follower_ids <- lookup_users(user)$followers_count
trunc_follower_time <- sum(trunc(n_follower_ids / param_users) * param_sleep)
follower_ids_estimate <- format(Sys.time() + trunc_follower_time, format = '%H:%M:%S')


## Per default verbose argument is set to TRUE. If set to FALSE message will not be printed.
if (verbose == TRUE) {
  message("Starting to fetch ", paste(n_follower_ids), " follower IDs. Expects to be done at ", paste(follower_ids_estimate), ".")
} else {
  NULL
}


## We're fetching user follower ids; if rate limit is encountered: sleeping for 15 minutes.
follower_ids <- get_followers(user, n = as.integer(n_follower_ids), parse = TRUE, retryonratelimit = TRUE, verbose = FALSE)


## Spliting user follower ids into chunks of follower ids with a max size of 90.000 ids.
## Afterwards writing chunk follower ids as txt files to the tmp path and its corresponding folder. Each chunk containing a maximum of 90.000 follower ids.
chunk_follower_ids <- split(follower_ids, (seq(nrow(follower_ids)) - 1) %/% param_users)
mapply(write.table, x = chunk_follower_ids, row.names = FALSE, col.names = FALSE, file = paste(names(chunk_follower_ids), "txt", sep = "."))


## We're listing and reading chunk follower ids from the tmp path
filenames <- list.files(path = tmp_path, pattern = "*.txt", full.names = TRUE)
ids <- lapply(filenames, read.table)


## For the sake of good order, checking whether there's more than one chunk of follower ids in tmp path. If false subroutine will be NULL. If TRUE: estimating and printing when the lookup users process will be done.
## Though if verbose is set to to FALSE message will not be printed.
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


## From chunk follower ids in tmp path user data is being looked up. Rate limit is avoided by sleeping after each chunk follower ids have been looked up.
## The last iteration will break when i is greater than the length of chunk follower ids -1.
## Thereby avoiding a Sys.sleep after the last lookup
## If verbose = FALSE message with time estimate will not be printed.
followers <- rep(NA, length(filenames))
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
  }


## Binding all the followers user data into a data frame
binded_followers <- do_call_rbind(followers)


## Resetting the user wd.
## If verbose = FALSE message will not be printed.
on.exit(setwd(root), add = TRUE)
if (verbose == TRUE) {
message("Jobs done at ", paste(format(Sys.time(), format = '%H:%M:%S')), ".")
} else {
  NULL
}
return(binded_followers)
}


## Function usage
fetched_followers <- fetcher(user = "fkoh111", path =  "~/Desktop/", verbose = FALSE)