

app_dependencies <- function() {
  shiny_examples_dir() %>%
    dir_dependencies()
}


get_dependencies <- function() {
  union(
    dir_dependencies("."),
    app_dependencies()
  )
}

update_dependencies <- function() {
  desc::desc_set(
    Imports = paste0(
      dir_dependencies("."),
      collapse = ",\n    "
    )
  )
}
