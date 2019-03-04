

download_repo <- function(repo = "rstudio/shiny-examples", save_dir =tempdir()) {

  folder_loc <- remotes:::github_remote(repo) %>% # parse repo
    remotes:::remote_download() %>% # return temp file location
    remotes:::decompress(save_dir) # untar folder, return uncompressed folder

  file.copy(
    system.file("wqy-zenhei.ttc", package = "testShinyExamples"),
    file.path(folder_loc, "022-unicode-chinese", "wqy-zenhei.ttc")
  )

  folder_loc
}
