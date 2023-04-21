# Encoding issues.
if(FALSE) {
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

    o = lapply(titles, readStatTable)
    names(o) = titles

    w = grepl("Monthly", titles)

    o2 = o
    o2[w] = lapply(o[w], transformVars)
    o2[!w] = lapply(o[!w], transformHourlyData)



    
    sol.rad = readStatTable("Average Hourly Statistics for Global Horizontal Solar Radiation")


    
}

readStatTable =
function(tableTitle = "Monthly Statistics for Dry Bulb temperatures",
         varName = "??",             
         file = "USA_CA_Bodega.Bay.CG.Light.Station.724995_TMYx.stat",
         encoding = "latin1")
{
    ll = readLines(file, encoding = encoding)
    i = grep(tableTitle, ll, fixed = TRUE)
    if(length(i) == 0) {
        stop("Can't find table ", tableTitle, " in ", file)
    }

    ll2 = ll[-(1:i)]
    ww = substring(ll2, 1, 4) == "   -" | substring(ll2, 1, 2) == " -"
    end = min(which(ww))

    ll3 = ll2[1:(end - 1L)]


    ll3 = ll3[ ll3 != ""]

    con = textConnection(ll3[-1], local = TRUE)
    on.exit(close(con))
    ans = read.table(con, sep = "\t", header = FALSE)


    #   all.na = sapply(ans, function(x) all(is.na(x)))
    #  But could find actual columns that have all NA values.
    ans = ans[, -c(1, ncol(ans))]

    ans[] = lapply(ans, trimws)

    # Could hard code the month names. But to be more general
    # we get them from the data.
    names(ans) = c(varName, month.abb)
    cols = trimws(strsplit(ll3[1], "\t")[[1]])
    cols = cols[ cols != ""]
    names(ans) = c(varName, cols)

    ans

}


transformHourlyData =
function(d, varName = names(d)[1])
{
    w = trimws(d[,1]) %in% c("Max Hour", "Min Hour")
    d = d[!w, ]

    vals = as.numeric(unlist(d[,-1]))
    ans = data.frame(value = vals, hour = rep(0:23, ncol(d) - 1), row.names = NULL)
    names(ans)[1] = varName
    ans$month = rep(names(d)[-1], each = nrow(d))
    ans
}


transformVars =
function(d)    
{
    w = d[,1] == "Day:Hour"
    #    vals = lapply(d[!w, -1], as.numeric)

    tmp = t(d[!w, -1])
    mode(tmp) = "numeric"
    ans = as.data.frame(tmp)
    # OR an alternative implementation
    if(FALSE) {
      tmp = t(d[!w, -1])
      ans = as.data.frame(tmp)
      ans[] = lapply(ans, as.numeric)
    }

    names(ans) = d[!w, 1]
    
    tmp = as.data.frame(t(d[w,-1]))
    anames = d[which(w) - 1L, 1]
    anames = paste0(anames, "Time")
    ans[ anames ] = lapply(tmp, cvtDayHour, names(d)[-1])

    ans
}

cvtDayHour =
function(x, month)
{
    str = sprintf("2023/%s/%s:00", month, x)
    as.POSIXct(strptime(str, "%Y/%b/%d:%H:%M"))
}
