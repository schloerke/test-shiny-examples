


globals <- new.env(parent = emptyenv())


shiny_examples_dir_update <- function() {
  # set the globals shiny locatino for further use
  globals$shiny_examples_loc <<- download_repo(
    desc::desc_get_field(
      "ShinyExamplesRepo",
      file = system.file("DESCRIPTION", package= "callr")
    ),
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
