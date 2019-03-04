
library(magrittr)

# account <- "rich_i"
# server <- "https://beta.rstudioconnect.com"
#
# root <- "."

deploy_apps <- function(
  account = "barret",
  server = "shinyapps.io",
  apps = TRUE,
  libpath = "_shiny-examples-lib",
  cores = 3
) {

  accts <- rsconnect::accounts()
  accts_found <- sum(
    (account %in% accts$name) &
    (server %in% accts$server)
  )

  cores <- as.numeric(cores)
  if (is.na(cores)) {
    stop("number of cores should be a numeric value")
  }

  if (accts_found == 0) {
    stop("please set an account with `rsconnect::setAccountInfo()` to match directly to `rsconnect::accounts()` information")
  } else if (accts_found > 1) {
    stop("more than one account matches `rsconnect::accounts()`. Fix it?")
  }

  libpath <- normalizePath(libpath)
  if (!dir.exists(libpath)) {
    dir.create(libpath, recursive = TRUE)
  }

  apps_folder <- shiny_examples_dir()
  apps_dirs <- apps_folder %>%
    list.dirs(recursive = FALSE) %>%
    basename() %>%
    grep("^\\d\\d\\d", ., value = TRUE) %>%
    file.path(apps_folder, .) %>%
    head()

  if (isTRUE(apps)) {
    # accept all apps
  } else {
    # filter apps
    app_num <- grep("^\\d\\d\\d", basename(apps_dirs), value = TRUE)
    matched <- apps %in% app_num
    apps_dirs <- apps_dirs[matched]
  }


  app_deps <- app_dependencies()

  withr::with_libpaths(libpath, {

  # callr::r(
  #   show = TRUE,
  #   libpath = libpath,
  #   args = list(
  #     apps_dirs = apps_dirs,
  #     app_deps = app_dependencies(),
  #     account = account,
  #     server = server
  #   ),
  #   function(apps_dirs, app_deps, account, server) {
      # })
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
      install_github <- function(repo, ..., upgrade = "always") {
        message("Installing github: ", repo)
        remotes::install_github(repo, ..., upgrade = upgrade)
      }

      # install all remotes and extra pkgs
      install_github(desc::desc_get_field("TestShinyExamplesRepo"), force = TRUE)

      # install all packages
      lapply(app_deps, maybe_install_pkg)

      # make sure remotes and pkgs are the last remaining ones
      install_github(desc::desc_get_field("TestShinyExamplesRepo"))

      pb <- progress::progress_bar$new(
        total = length(apps_dirs) / cores,
        format = "[:bar] :current/:total eta::eta :name\n"
      )
      deploy_apps_ <- function(app_dir) {
        pb$tick(tokens = list(name = app_dir))
        res <- rsconnect::deployApp(
          appDir = app_dir,
          appName = basename(app_dir),
          account = account,
          server = server,
          # logLevel = 'verbose',
          launch.browser = FALSE,
          forceUpdate = TRUE
        )
        if (inherits(res, 'try-error')) {
          return(1)
        } else {
          return(0)
        }
      }
      deploy_res <-
        if (cores > 1) {
          parallel::mclapply(apps_dirs, deploy_apps_, mc.cores = cores)
        } else {
          lapply(apps_dirs, deploy_apps_)
        }
      deploy_res <- unlist(deploy_res)

      deploy_warnings <- warnings()
      if (length(deploy_warnings) != 0) {
        cat("\n")
        print(deploy_warnings)
      }

      if (any(deploy_res != 0)) {
        error_apps <- grep("^\\d\\d\\d", basename(apps_dirs[deploy_res != 0]), value = TRUE)
        cat(
          "\nError deploying apps:\n",
          paste0("c(\"",
            paste0(error_apps, collapse = "\", \""),
          "\")", collapse = "\n"),
          "\n",
          sep = ""
        )
      }

    }
  )


}
