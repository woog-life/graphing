library(ggridges)
library(ggplot2)
library(viridis)
library(hrbrthemes)
library(DBI)
library(aws.s3)

# Connect to a specific postgres database i.e. Heroku
con <- dbConnect(RPostgres::Postgres(), dbname = Sys.getenv("POSTGRES_DB"),
                 host = Sys.getenv("POSTGRES_HOSTNAME"),
                 port = 5432,
                 user = Sys.getenv("POSTGRES_USER"),
                 password = Sys.getenv("POSTGRES_PASSWORD"))

dtab <- dbGetQuery(con, "SELECT * FROM lake_data WHERE lake_id='69c8438b-5aef-442f-a70d-e0d783ea2b38';")
data_frame <- as.data.frame(dtab)
data_frame$CST <- with(data_frame, as.Date(timestamp))
data_frame$Month <- months(as.Date(data_frame$CST))

# delete this in may/june
data_frame$Month <- factor(data_frame$Month, levels = rev(list("June", "July", "August", "September", "October", "November", "December", "January", "February", "March")))

ggplot(data_frame, aes(x = `temperature`, y = `Month`, fill = ..x..)) +
  geom_density_ridges_gradient(scale = 3, rel_min_height = 0.01) +
  scale_fill_viridis(name = "Temp. [F]", option = "C") +
  labs(title = 'Grosser Woog') +
  theme(
    legend.position = "none",
    panel.spacing = unit(0.1, "lines"),
    strip.text.x = element_text(size = 8)
  )

ggsave("woog.png")

# `region` must be empty, the s3 library automatically transforms the url to this: `{region}.{endpoint}`
# this doesn't work well with the exoscale endpoint since it's `sos-{region}.exo.io`
put_object(file = "woog.png", object = "woog.png", bucket = "wooglife", region = "")
