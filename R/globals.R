




globals <- new.env(parent = emptyenv())

globals$testing_location <- "schloerke/test-shiny-examples"
globals$example_location <- "rstudio/shiny-examples@rc-v1.3.0"


shiny_examples_dir_update <- function() {
  # set the globals shiny locatino for further use
  globals$shiny_examples_loc <<- download_repo(
    globals$example_location,
    tempdir()
  )
  globals$shiny_examples_loc
}
shiny_examples_dir <- function() {
  ret <- globals$shiny_examples_loc
  if (!is.null(ret)) {
    return(ret)
  }
  return(
    shiny_examples_dir_update()
  )
}
