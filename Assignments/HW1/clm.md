
<!-- Fro Read.md in ComplexFile/ -->


The .clm file starts with
```
*CLIMATE
# ascii climate file from USA_Bodega.Bay.CG.Light.Station EPW file,
# defined in: .\EPW_Output\USA_CA_Bodega.Bay.CG.Light.Station.724995_TMYx.clm
# col 1: Diffuse solar on the horizontal (W/m**2)
# col 2: External dry bulb temperature   (Tenths DEG.C)
# col 3: Direct normal solar intensity   (W/m**2)
# col 4: Prevailing wind speed           (Tenths m/s)
# col 5: Wind direction     (clockwise deg from north)
# col 6: Relative humidity               (Percent)
Bodega.Bay.CG.Light.Station - USA     # site name
 2021,38.31,-3.05,0   # year, latitude, long diff, direct normal rad flag
 1,365    # period (julian days)
* day  1 month  1
 0,75,0,11,329,92
 0,72,0,20,338,91
 0,75,0,13,341,93
 0,61,0,13,338,95
 0,57,0,15,335,94
 0,65,0,25,348,93
```

The file starts with metadata starting with `#`.

Then there are three lines providing the
+ location and a comment (`# site name`).
+ year, and geolocation and a comment
+ and the period.

Next is a sequence of data for a given day
```
* day  1 month  1
```
There may be multiple days.
Each day starts with, e.g., 
```
* day  1 month  1
```
And the meta data tells us there are 365 days.


We start by reading all the lines of the file into a character vector:
```r
f = "USA_CA_Bodega.Bay.CG.Light.Station.724995_TMYx.clm"
ll = readLines(f)
```

We can find the meta data lines starting with # with
```
wc = substring(ll, 1, 1) == "#"
```

We can find the `* day `

```
w = substring(ll, 1, 1) == "*"
table(w)

w = substring(ll, 1, 5) == "* day"
table(w)

days = split(ll, cumsum(w))[-1]
readDay = 
function(text)
{
   text = text[-1]
   con = textConnection(text, open = "r", local = TRUE)
   on.exit(close(con))
   read.csv(con, header = FALSE)
}

readDay(days[[1]])
```

Check result is correct before proceeding.

```r
days.df = lapply(days, readDay)

table(sapply(days.df, nrow))

table(sapply(days.df, ncol))

clm = do.call(rbind, days.df)

names(clm) = c("diffuseSolar", "temp", "directSolar", "windSpeed", "windDirection", "humidity")
```

day of year is day 1 month 1 ....
```r
clm$date = seq(as.Date("2023/1/1"), length = 365, by = 1)


summary(clm[-1])
sapply(clm, function(x) table(is.na(x)))


pairs(clm)
pairs(clm, pch = ".")

par(mfrow = c(2, 3))
sapply(names(clm)[-1], function(x) plot(density(clm[[x]], main = x)))  # main passed to density. See warnings.
sapply(names(clm)[-1], function(x) plot(density(clm[[x]]), main = x))
```


## Alternative Approach

Another approach is remove the "* day" lines.

```
ll2 = ll[!w]
ll3 = ll2[ (which(w)[1]) : length(ll2) ]
```
or 
```
ll3 = ll2[ -(1:(which(w)[1] - 1)) ]
```

Then
```
clm2 = readDay(ll3)
```

But that drops the first line.
Could 
+ keep that first line or 
+ add a parameter to readDay to control whether to drop it or not, or
+ have readDay determine if first line starts with "* day"


