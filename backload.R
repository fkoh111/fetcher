rm(list=ls())

x <- c("fkoh111")






tmp_get_followers <- get_followers(x, n = 200000000, parse = TRUE, retryonratelimit = TRUE)

root <- getwd()
folder <- paste("id_chunks", x)
if (file.exists(folder)){
  setwd(file.path(root, folder))
} else {
  dir.create(file.path(root, folder))
  setwd(file.path(root, folder))
}


#Split follower IDs into appropriate .txt chunks and write-out
chunks_tmp_followers <- split(tmp_get_followers, (seq(nrow(tmp_get_followers))-1) %/% 3600)

for (i in 1:length(chunks_tmp_followers)) {
  write.table(chunks_tmp_followers[i], row.names = FALSE, col.names = FALSE, file=paste0(names(chunks_tmp_followers)[i], ".txt"))
}

#Read id chunk files
filenames <- list.files(path = getwd(), pattern="*.txt", full.names = TRUE)
ldf <- lapply(filenames, read.table)

#Lookup id chunk files and sleep when rate limit is encountered
out <- rep(NA, length(list.files()))
if(length(filenames) > 1)
  for (i in seq_along(ldf)) {
    out[i] <- lapply(ldf[i], lookup_users)
    Sys.sleep(15*60)
  } else {
    for (i in seq_along(ldf)) {
      out[i] <- lapply(ldf[i], lookup_users)}}

#Concatenate out and write out2db
out2db <- rbindlist(out, fill=TRUE)

#Clean up
setwd(root)
system(paste("rm -rf '", folder,"'", sep = ""))
return(out2db)