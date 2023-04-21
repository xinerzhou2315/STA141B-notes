source("readStatTables.R")

# Code developed/trained on Bodega

statFiles = list.files("ZIP/Files", pattern = ".stat$", full = TRUE)


titles = c("Monthly Statistics for Dry Bulb temperatures",
           "Monthly Statistics for Dew Point temperatures",
           "Average Hourly Statistics for Dry Bulb temperatures",
           "Average Hourly Statistics for Dew Point temperatures",
           "Average Hourly Relative Humidity",
           "Monthly Wind Direction {Interval 11.25 deg from displayed deg)",
           "Average Hourly Statistics for Global Horizontal Solar Radiation",
           "Monthly Statistics for Wind Speed",
           "Average Hourly Statistics for Wind Speed"
           )

zip = lapply(statFiles,
              function(stat) {

                  o = lapply(titles, readStatTable, file = stat)
                  names(o) = titles

                  w = grepl("Monthly", titles)

                  o2 = o
                  o2[w] = lapply(o[w], transformVars)
                  o2[!w] = lapply(o[!w], transformHourlyData)

                  o2
              })

names(zip) = gsub(".stat", "", basename(statFiles))

stopifnot(length(zip) == 5)


nr = sapply(zip, function(z) sapply(z, nrow))
stopifnot( all(apply(nr, 1, function(x) length(unique(x))) == 1) )


ggplot(zip[[1]][[3]], aes(y = `??`, x = hour, color = month)) + geom_point()

