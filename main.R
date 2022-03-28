library(ggridges)
library(ggplot2)
library(viridis)
library(hrbrthemes)


weather_data <- read.csv("result.csv")
weather_data$Month<-months(as.Date(weather_data$CST))

# can be reenabled as soon as we've got data for a whole year (start of june or during may)
# weather_data$Month<-factor(weather_data$Month, levels=rev(unique(lincoln_weather$Month)))
weather_data$Month<-factor(weather_data$Month, levels=rev(list("June", "July", "August", "September", "October", "November", "December", "January", "February", "March")))

ggplot(weather_data, aes(x = `Temperature`, y = `Month`, fill = ..x..)) +
  geom_density_ridges_gradient(scale = 3, rel_min_height = 0.01) +
  scale_fill_viridis(name = "Temp. [F]", option = "C") +
  labs(title = 'Grosser Woog') +
  theme(
    legend.position="none",
    panel.spacing = unit(0.1, "lines"),
    strip.text.x = element_text(size = 8)
  )

ggsave("woog.png")
