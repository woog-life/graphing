library(ggridges)
library(ggplot2)
library(viridis)
library(hrbrthemes)
library(DBI)
library(aws.s3)
library(httr)
library(jsonlite)
library(svglite)

monthConversion <- c(
  "January" = "Januar",
  "February" = "Februar",
  "March" = "März",
  "April" = "April",
  "May" = "Mai",
  "June" = "Juni",
  "July" = "Juli",
  "August" = "August",
  "September" = "September",
  "October" = "Oktober",
  "November" = "November",
  "December" = "Dezember"
)

convertMonth <- function(m) {
  return(monthConversion[m])
}

retrieveDataFrameForLakeId <- function(con, lakeId) {
  query <- paste0("SELECT * FROM lake_data WHERE lake_id='", lakeId, "';")
  dtab <- dbGetQuery(con, query)
  data_frame <- as.data.frame(dtab)
  data_frame$CST <- with(data_frame, as.Date(timestamp))
  data_frame$Month <- months(as.Date(data_frame$CST))
  data_frame$Month <- mapply(convertMonth, data_frame$Month)
  data_frame$Month <- factor(data_frame$Month, levels = rev(list('Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember')))

  return(data_frame)
}

createPlot <- function(data_frame, title, subtitle, filename) {
  ggplot(data_frame, aes(x = `temperature`, y = `Month`, fill = after_stat(x))) +
    stat_density_ridges(
      geom = "density_ridges_gradient", calc_ecdf = TRUE,
      quantiles = 3, quantile_lines = TRUE
    ) +
    scale_fill_viridis(name = "Temp. [F]", option = "C") +
    labs(title = title, subtitle = subtitle) +
    xlab("Temperatur") +
    ylab("Month") +
    theme(
      legend.position = "none",
      panel.spacing = unit(0.1, "lines"),
      strip.text.x = element_text(size = 8)
    )

  ggsave(filename)
}

createLinePlot <- function(df, title, subtitle, filename) {
  ggplot(df, aes(y = `temperature`, x = `timestamp`)) +
    geom_line() +
    scale_fill_viridis(name = "Temp. [F]", option = "C") +
    labs(title = title, subtitle = subtitle) +
    xlab("Monat") +
    ylab("Temperatur") +
    theme(
      legend.position = "none",
      panel.spacing = unit(0.1, "lines"),
      strip.text.x = element_text(size = 8)
    )

  ggsave(filename)
}

apiUrl <- function() {
  Sys.getenv("API_URL", unset = "http://backend:8080")
}

getLakeIds <- function() {
  url <- modify_url(apiUrl(), path = "lake")
  response <- GET(url)

  fromJSON(content(response, "text"), simplifyVector = FALSE)
}

lakeFromApi <- function(lakeId) {
  url <- modify_url(apiUrl(), path = paste0("lake/", lakeId))
  response <- GET(url)

  if (response$status_code == 200) {
    fromJSON(content(response, "text"), simplifyVector = FALSE)
  } else {
    NULL
  }
}

bucketName <- Sys.getenv("BUCKET_NAME", unset = "wooglife")

# Connect to a specific postgres database i.e. Heroku
con <- dbConnect(RPostgres::Postgres(), dbname = Sys.getenv("POSTGRES_DB"),
                 host = Sys.getenv("POSTGRES_HOSTNAME"),
                 port = 5432,
                 user = Sys.getenv("POSTGRES_USER"),
                 password = Sys.getenv("POSTGRES_PASSWORD"))

lakes <- getLakeIds()$lakes

for (i in seq_along(lakes)) {
  lake <- lakes[[i]]

  data_frame <- retrieveDataFrameForLakeId(con, lake$id)
  apiLake <- lakeFromApi(lake$id)
  if (is.null(apiLake)) {
    print(paste0("failed to retrieve data for '", lake$id, "'"))
    next
  }

  dateFormat <- "%d.%m.%Y"

  firstDate <- format(head(data_frame$CST[[1]]), format = dateFormat)
  lastDate <- format(tail(data_frame$CST)[[1]], format = dateFormat)
  subtitle <- paste(firstDate, "-", lastDate)

  title <- paste0(lake$name, " (", nrow(data_frame), " Datenpunkte)")
  filename <- paste0(lake$id, ".svg")
  filename_line <- paste0(lake$id, "_line.svg")

  createPlot(data_frame, title, subtitle, filename)

  # we only care about a shorter timeframe with the linegraph
  df <- tail(data_frame, 1440)
  firstDate <- format(head(df$CST[[1]]), format = dateFormat)
  lastDate <- format(tail(df$CST)[[1]], format = dateFormat)
  subtitle <- paste(firstDate, "-", lastDate)

  title <- paste0(lake$name, " (", nrow(df), " Datenpunkte)")
  createLinePlot(df, title, subtitle, filename_line)
  break
  # `region` must be empty, the s3 library automatically transforms the url to this: `{region}.{endpoint}`
  # this doesn't work well with the exoscale endpoint since it's `sos-{region}.exo.io`
  tryCatch(
    put_object(file = filename, object = filename, bucket = bucketName, region = "", acl = "public-read"),
    error = function(err) {
      print(paste0("failed to put '", filename, "' into '", bucketName, "' bucket:"))
      print(err)
    }
  )
}

dbDisconnect(con)
