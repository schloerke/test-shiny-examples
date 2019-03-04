api_get_ <- function(server, api_key) {
  server <- rsconnect::serverInfo(server)$url
  function(route) {
    httr::GET(
      paste0(server, route),
      httr::content_type_json(),
      httr::add_headers(
        Authorization = paste0("Key ", api_key)
      )
    ) %>%
      httr::content(as = "parsed")
  }
}
api_post_ <- function(server, api_key) {
  server <- rsconnect::serverInfo(server)$url
  function(route, body) {
    httr::POST(
      paste0(server, route),
      body = body,
      encode = "json",
      httr::add_headers(
        Authorization = paste0("Key ", api_key)
      )
    ) %>%
      httr::content(as = "parsed")
  }
}


#' Set applications to be public
#'
#' @param account,server args supplied to `[rsconnect::deployApp]`
#' @param api_key API key generated from the connect server
#' @export
#' @examples
#' \dontrun{
#'   set_public("barret", "beta.rstudioconnect.com", "APIKEY")
#' }
set_public <- function(account, server, api_key) {
  api_get <- api_get_(server, api_key)
  api_post <- api_post_(server, api_key)

  acctInfo <- rsconnect::accountInfo(account, server)
  appsInfo <- api_get(paste0("/applications?count=1000&filter=account_id:", acctInfo$accountId))
  apps <- appsInfo$applications

  example_names <-
    shiny_examples_dir() %>%
    list.dirs(recursive = FALSE) %>%
    basename() %>%
    grep("^\\d\\d\\d", ., value = TRUE)
  apps_names <-  vapply(apps, `[[`, character(1), "name")
  apps <- apps[apps_names %in% example_names]

  apps_names <- vapply(apps, `[[`, character(1), "name")
  # alpha sort
  apps <- apps[order(apps_names)]

  pb <- progress::progress_bar$new(
    total = length(apps),
    format = "[:bar] :current/:total eta::eta :app\n",
    show_after = 0,
    clear = FALSE
  )
  lapply(
    apps,
    function(app) {
      pb$tick(tokens = list(app = app$name))
      api_post(
        paste0("/applications/", app$id),
        list(
          id = app$id,
          access_type = "all"
        )
      )
    }
  )

  app_names <- vapply(apps, `[[`, character(1), "name")
  max_len <- max(nchar(app_names))
  app_names <- vapply(app_names, character(1), USE.NAMES = FALSE, FUN = function(x) {
    paste0(
      x,
      paste0(rep(" ", max_len - nchar(x)), collapse = "")
    )
  })
  app_urls <- vapply(apps, `[[`, character(1), "url")

  cat(
    "\nApplications deployed: \n",
    paste0(app_names, " - ", app_urls, collapse = "\n"),
    "\n",
    sep = ""
  )

  invisible(app_urls)
}
