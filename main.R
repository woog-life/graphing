library(ggridges)
library(ggplot2)
library(viridis)
library(hrbrthemes)
library(DBI)
library(aws.s3)
library(httr)
library(jsonlite)

retrieveDataFrameForLakeId <- function (con, lakeId) {
  query <- paste0("SELECT * FROM lake_data WHERE lake_id='", lakeId, "';")
  dtab <- dbGetQuery(con, query)
  data_frame <- as.data.frame(dtab)
  data_frame$CST <- with(data_frame, as.Date(timestamp))
  data_frame$Month <- months(as.Date(data_frame$CST))

  # delete this in may/june
  data_frame$Month <- factor(data_frame$Month, levels = rev(list("June", "July", "August", "September", "October", "November", "December", "January", "February", "March", "April")))

  return(data_frame)
}

createPlot <- function(data_frame, title, filename) {
  ggplot(data_frame, aes(x = `temperature`, y = `Month`, fill = ..x..)) +
    geom_density_ridges_gradient(scale = 3, rel_min_height = 0.01) +
    scale_fill_viridis(name = "Temp. [F]", option = "C") +
    labs(title = title) +
    theme(
      legend.position = "none",
      panel.spacing = unit(0.1, "lines"),
      strip.text.x = element_text(size = 8)
    )

  ggsave(filename)
}

getLakeIds <- function() {
  url <- modify_url("https://api.woog.life", path="lake")
  response <- GET(url)

  fromJSON(content(response, "text"), simplifyVector = FALSE)
}

lakeFromApi <- function(lakeId) {
  url <- modify_url("https://api.woog.life", path=paste0("lake/", lakeId))
  response <- GET(url)

  fromJSON(content(response, "text"), simplifyVector = FALSE)
}

# Connect to a specific postgres database i.e. Heroku
con <- dbConnect(RPostgres::Postgres(), dbname = Sys.getenv("POSTGRES_DB"),
                 host = Sys.getenv("POSTGRES_HOSTNAME"),
                 port = 5432,
                 user = Sys.getenv("POSTGRES_USER"),
                 password = Sys.getenv("POSTGRES_PASSWORD"))

lakes <- getLakeIds()$lakes
# print(lakes)

for (i in 1:length(lakes)) {
  lake <- lakes[[i]]

  data_frame <- retrieveDataFrameForLakeId(con, lake$id)
  lake <- lakeFromApi(lake$id)
  title <- lake$name
  filename <- paste0(lake$id, ".png")

  createPlot(data_frame, title, filename)

  # `region` must be empty, the s3 library automatically transforms the url to this: `{region}.{endpoint}`
  # this doesn't work well with the exoscale endpoint since it's `sos-{region}.exo.io`
  put_object(file = filename, object = filename, bucket = "wooglife", region = "")
}
