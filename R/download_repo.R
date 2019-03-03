

download_repo <- function(repo = "rstudio/shiny-examples", save_dir =tempdir()) {

  remotes:::github_remote(repo) %>% # parse repo
    remotes:::remote_download() %>% # return temp file location
    remotes:::decompress(save_dir) # untar folder, return uncompressed folder

}
