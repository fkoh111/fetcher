## Fetcher v. 0.9.3

**Author:** Frederik Kok Hansen  
frederik_kok@icloud.com

Fetcher is a UDF for the rtweet package.  
The purpose of fetcher is **#1** to make it easy for R users to fetch followers' user data from Twitter accounts having more than 90.000 followers and **#2** dealing with rate limits in an automated manner.  

Overall the function `fetcher()` is a wrapper for the `lookup_users()` function. Hence the two functions takes the same type of arguments. That is either a *user ID* or a *screen name* of a Twitter account whose followers you want to fetch.

As with the functions from the rtweet package, it is assumed that you have a non-exhausted Twitter token in your environment for the function to work properly. 

Please note that the function has only been tested on **nix* OS.

For any questions please don't hesitate to contact me on GitHub or by e-mail. Also, any pull requests and proposals are more than welcome.
