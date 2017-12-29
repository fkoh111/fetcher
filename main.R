
        ##################################################################################
       ### FETCHER (v. 0.9)                                                           ###
      ### An external function for the rtweet package making it easy for R users to  ###
     ### fetch followers' user data from Twitter accounts without having to worry   ###
    ### about rate limits and users with more than 90.000 followers.               ###
   ### Use the fetcher function as any of the original rtweet functions.          ###
  ### For further information see github: https://github.com/fkoh111/fetcher     ###
 ##################################################################################


## Defining function fetcher() with one argument. Either a Twitter username or a user id
fetcher <- function (x) {
        
## Check for required packages; download, install and load if necessary
dependencies <- function(y) {
  y <- as.character(match.call() [[2]])
  if (!require(y, character.only = TRUE)){
    install.packages(pkgs = y, repos = "http://cran.r-project.org")
    require(y, character.only = TRUE)
  }
}
dependencies("data.table")
dependencies("lubridate")
dependencies("ROAuth")
dependencies("rtweet")

## Initialize temporary container for follower ids.
root <- getwd()
folder <- paste("id_chunks", x, sep = "_")
if (file.exists(folder)){
  setwd(file.path(root, folder))
} else {
  dir.create(file.path(root, folder))
  setwd(file.path(root, folder))
}

## Fetch follower ids; if rate limit is encountered, script will sleep for 15 minutes
follower_ids <- get_followers(x, n = 200000000, parse = TRUE, retryonratelimit = TRUE)

## Split follower ids into .txt chunks
chunks_follower_ids <- split(follower_ids, (seq(nrow(follower_ids))-1) %/% 90000)

## Write follower ids to temporary container
for (i in 1:length(chunks_follower_ids)) {
  write.table(chunks_follower_ids[i], row.names = FALSE, col.names = FALSE, file=paste0(names(chunks_follower_ids)[i], ".txt"))
}

## Read id chunk files
filenames <- list.files(path = getwd(), pattern="*.txt", full.names = TRUE)
ids <- lapply(filenames, read.table)

## Lookup id chunk files and sleep if rate limit is encountered
followers <- rep(NA, length(list.files()))
if(length(filenames) > 1)
  for (i in seq_along(ids)) {
    followers[i] <- lapply(ids[i], lookup_users)
    message("Rate limit encountered - going to sleep for 15 minutes at ", paste(format(Sys.time(), format = '%H:%M:%S')))
    Sys.sleep(15*60)
  } else {
    for (i in seq_along(ids)) {
      followers[i] <- lapply(ids[i], lookup_users)}}

## Bind followers
binded_followers <- rbindlist(followers, fill=TRUE)

## Clean up
setwd(root)
system(paste("rm -rf '", folder,"'", sep = ""))

return(binded_followers)
}


## Function usage
fetched_followers <- fetcher("...")