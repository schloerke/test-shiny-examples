# test-shiny-examples


Test the shiny examples before a release.

Perform this in a terminal to avoid installation issues within the IDE.

#### Examples

```r
library(testShinyExamples)

# double check existing accounts
rsconnect::accounts()

# deploy the first three apps to barret.shinyapps.io
deploy_apps("barret", "shinyapps.io", c("001", "002", "003"))

# deploy all apps to barret.shinyapps.io
deploy_apps("barret", "shinyapps.io")

# deploy all apps user barret on beta.rstudioconnect.com
deploy_apps("barret", "beta.rstudioconnect.com")
# make all shiny example apps on RStudio Connect apps public
# (only shiny example apps)
set_public("barret", "beta.rstudioconnect.com")
```
