
#' Deploy apps to a server
#'
#' @param account,server args supplied to `[rsconnect::deployApp]`
#' @param apps A vector of three digit character values or `TRUE` to deploy all apps
#' @param libpath library location. (Creates the path if it does not exist.)
#' @param cores number of cores to use when deploying
#' @export
deploy_apps <- function(
  account = "barret",
  server = "shinyapps.io",
  apps = TRUE,
  libpath = "_shiny-examples-lib",
  cores = 3
) {

  is_missing <- list(
    account = missing(account),
    server = missing(server),
    apps = missing(apps),
    libpath = missing(libpath),
    cores = missing(cores)
  )

  accts <- rsconnect::accounts()
  accts_found <- sum(
    (account %in% accts$name) &
    (server %in% accts$server)
  )
  if (accts_found == 0) {
    stop("please set an account with `rsconnect::setAccountInfo()` to match directly to `rsconnect::accounts()` information")
  } else if (accts_found > 1) {
    stop("more than one account matches `rsconnect::accounts()`. Fix it?")
  }

  cores <- as.numeric(cores)
  if (is.na(cores)) {
    stop("number of cores should be a numeric value")
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
    file.path(apps_folder, .)

  if (isTRUE(apps)) {
    # accept all apps
  } else {
    # filter apps
    app_num <- grep("^\\d\\d\\d", basename(apps_dirs), value = TRUE) %>%
      sub("-.*", "", .)
    apps_dirs <- apps_dirs[app_num %in% apps]
  }


  app_deps <- app_dependencies()

  withr::with_libpaths(libpath, {

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
      # message("Installing github: ", repo)
      remotes::install_github(repo, ..., upgrade = upgrade)
    }

    # install all remotes and extra pkgs
    install_github(desc::desc_get_field("TestShinyExamplesRepo"))

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
      dput_arg <- function(x) {
        f <- file()
        on.exit({
          close(f)
        })
        dput(x, f)
        ret <- paste0(readLines(f), collapse = "\n")
        ret
      }
      error_apps <-
        grep("^\\d\\d\\d", basename(apps_dirs[deploy_res != 0]), value = TRUE) %>%
        sub("-.*", "", .)
      args <- c(
        if (!is_missing$account) paste0("account = ", dput_arg(account)),
        if (!is_missing$server) paste0("server = ", dput_arg(server)),
        paste0("apps = ", dput_arg(error_apps)),
        if (!is_missing$libpath) paste0("libpath = ", dput_arg(libpath)),
        if (!is_missing$cores) paste0("cores = ", dput_arg(cores))
      )
      fn <- paste0(
        "deploy_apps(", paste0(args, collapse = ", "),")"
      )
      cat(
        "\nError deploying apps:\n",
        fn,
        "\n",
        sep = ""
      )
    }

  })


}
