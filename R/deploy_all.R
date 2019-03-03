
library(magrittr)

# account <- "rich_i"
# server <- "https://beta.rstudioconnect.com"
#
# root <- "."

deploy_apps <- function(
  account = "barret",
  server = "https://shinyapps.io",
  libpath = "_shiny-examples-lib"
) {


  apps_folder <- shiny_examples_dir()
  libpath <- normalizePath(libpath)
  if (!dir.exists(libpath)) {
    dir.create(libpath, recursive = TRUE)
  }

  apps_dirs <- apps_folder %>%
    list.dirs(recursive = FALSE) %>%
    basename() %>%
    grep("^\\d\\d\\d", ., value = TRUE) %>%
    file.path(apps_folder, .) %>%
    head()

  callr::r(
    show = TRUE,
    libpath = libpath,
    args = list(
      app_deps = app_dependencies()
    ),
    function(app_deps) {
      message("Library Path: ", .libPaths()[1])

      maybe_install_pkg <- function(pkg, lib = .libPaths()[1]) {
        tryCatch({
          packageVersion(pkg, lib.loc = lib)
        }, error = function(e) {
          message("Installing: ", pkg)
          install.packages(pkg, lib, dependencies = TRUE)
        })
      }

      maybe_install_pkg("remotes")
      install_github <- function(repo, ...) {
        # message("Installing github: ", repo)
        remotes::install_github(repo, ...)
      }

      # install all remotes and extra pkgs
      install_github(desc::desc_get_field("TestShinyExamplesRepo"))

      # install all packages
      lapply(app_deps, maybe_install_pkg)

      # make sure remotes and pkgs are the last remaining ones
      install_github(desc::desc_get_field("TestShinyExamplesRepo"))

      pb <- progress::progress_bar$new(
        total = length(apps),
        format = "[:bar] :current/:total eta::eta :name\n"
      )
      lapply(apps, function(appDir) {
        pb$tick(tokens = list(name = appDir))
        rsconnect::deployApp(
          appDir = appDir,
          appName = appDir,
          account = account,
          server = server,
          logLevel = 'verbose',
          launch.browser = FALSE,
          forceUpdate = TRUE
        )
      })
    }
  )


}
