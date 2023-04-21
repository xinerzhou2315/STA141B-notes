

One of the important lessons from this assignment should be  that
a large amount of time involves
+ debugging code
+ verifying the results 


# Reading a .pvsyst

This is a relatively straightforward CSV file
except for

+ the comment lines at the top which we can ignore with commen.char
+ the 14th line immediately after the line with the column names that provides the units.

We don't want the 14th line to be read as part of the data.frame
as it will change the types of each column from numbers to character vectors.
We can 

+ read it and then omit it and change the types of the relevant columns
+ skip past this line to read the values and then get the column names separately.

```{r}
pv.files =  list.files("ZIP/Files", pattern = ".pvsyst", full = TRUE)
```

```{r}
p = read.csv(pv.files[1])
```
This gives an error
```{r}
  duplicate 'row.names' are not allowed
```


We can try
```{r}
p = read.csv(pv.files[1], row.names = NULL)
```
Seems to be fine. But 
```{r}
dim(p)
```
shows only 2 columns.

We expect at most
```{r}
length(readLines(pv.files[1]))
```
rows and we got 52583.
So this is all wrong.


We can fix read.csv() to read these data, but we can also try the readr_csv function in the readr
package 
```{r}
p = read_csv(pv.files[1])
```
This succeeds but gives a warning
```
Warning: One or more parsing issues, see `problems()` for details
```
The result has only one column.
Note it is also of class tibble rather than data.frame.

The first 6 entries correspond to some of  the comment lines.
Let's skip these lines
```{r}
p = read_csv(pv.files[1], skip = 12)
```

Now we can check the class of each column
```{r}
sapply(p, class)
```

```
     Year       Month         Day        Hour      Minute         GHI         DHI         DNI        Tamb     WindVel     WindDir 
"numeric"   "numeric"   "numeric"   "numeric"   "numeric" "character" "character" "character" "character" "character" "character" 
```

We see the character vectors corresponding to the columns where the units were provided
```{r}
head(p)
```
```
# A tibble: 6 × 11
   Year Month   Day  Hour Minute GHI   DHI   DNI   Tamb  WindVel WindDir
  <dbl> <dbl> <dbl> <dbl>  <dbl> <chr> <chr> <chr> <chr> <chr>   <chr>  
1    NA    NA    NA    NA     NA W/m2  W/m2  W/m2  deg.C m/sec   "\xb0" 
2  2059     1     1     1     30 0     0     0     5.000 4.00    "90"   
3  2059     1     1     2     30 0     0     0     4.000 4.00    "40"   
4  2059     1     1     3     30 0     0     0     3.000 5.00    "70"   
5  2059     1     1     4     30 0     0     0     1.000 2.00    "40"   
6  2059     1     1     5     30 0     0     0     1.000 3.00    "80"   
```

We can drop the first row and then conver the columns
```{r}
p1 = p[-1,]
w = sapply(p1, is.character)
p1[w] = sapply(p1[w], as.numeric)
```

Now we have the data and need to verify the results.


```{r}
p = read_csv(pv.files[1], skip = 12)
p1 = p[-1,]
w = sapply(p1, is.character)
p1[w] = sapply(p1[w], as.numeric)
p1 = as.data.frame(p1)
```

As an aside, note the "\xb0" in the units value for WindDir.
This should be a degree symbol. 
In this situation, we are discarding this value.
However, if we did need to read this correctly, we need to tell read_csv()
to use Latin1 encoding rather thant UTF-8.
We can do this with
```{r}
p = read_csv(pv.files[1], skip = 12, locale = locale(encoding = "latin1"))
```


### Approach 2
A different approach is to skip the column names and units
and then read the column names separately and 
set the names on the data.frame:
```{r}
p2 = read.csv(pv.files[1], skip = 14, header = FALSE)
h = read.csv(pv.files[1], skip = 12, nrow = 1, header = FALSE)
names(p2) = h[1,]
```

Alternatively, we can use readLines() and strsplit() to get the column names:
```{r}
p2 = read.csv(pv.files[1], skip = 14, header = FALSE)
h = readLines(pv.files[1], n = 12)[12]
names(p2) = strsplit(h, ",")[[1]]
```

We can compare p1 and p2 to check they are the same.
```{r}
identical(p1, p2)
```
This is FALSE.

We can use the more informative all.equal() to see what parts are different:
```{r}
all.equal(p1, p2)
```
This gives TRUE.
When identical gives FALSE and all.equal gives TRUE, this is typically due to different precision in numbers.

Let's examine the class of each colum in the two data frames.
```{r}
all(sapply(p1, class) ==  sapply(p2, class))
```
gives FALSE.
Examining the classes, 
```{r}
cbind(sapply(p1, class), sapply(p2, class))
```
```
        [,1]      [,2]     
Year    "numeric" "integer"
Month   "numeric" "integer"
Day     "numeric" "integer"
Hour    "numeric" "integer"
Minute  "numeric" "integer"
GHI     "numeric" "integer"
DHI     "numeric" "integer"
DNI     "numeric" "integer"
Tamb    "numeric" "numeric"
WindVel "numeric" "numeric"
WindDir "numeric" "integer"
```
we see read_csv treats the integer values in the data as numeric values, whereas read.csv does not.
We can control this with col_type and colClasses in the two functions, respectively.


To verify the data, we also compute a summary of each column
```{r}
summary(p2)
```
```
      Year          Month             Day             Hour      
 Min.   :2059   Min.   : 1.000   Min.   : 1.00   Min.   : 1.00  
 1st Qu.:2059   1st Qu.: 4.000   1st Qu.: 8.00   1st Qu.: 6.75  
 Median :2059   Median : 7.000   Median :16.00   Median :12.50  
 Mean   :2059   Mean   : 6.526   Mean   :15.72   Mean   :12.50  
 3rd Qu.:2059   3rd Qu.:10.000   3rd Qu.:23.00   3rd Qu.:18.25  
 Max.   :2059   Max.   :12.000   Max.   :31.00   Max.   :24.00  
     Minute        GHI              DHI              DNI       
 Min.   :30   Min.   :   0.0   Min.   :  0.00   Min.   :  0.0  
 1st Qu.:30   1st Qu.:   0.0   1st Qu.:  0.00   1st Qu.:  0.0  
 Median :30   Median :  16.0   Median :  8.00   Median :  0.0  
 Mean   :30   Mean   : 217.8   Mean   : 48.92   Mean   :283.9  
 3rd Qu.:30   3rd Qu.: 408.0   3rd Qu.: 90.00   3rd Qu.:640.0  
 Max.   :30   Max.   :1016.0   Max.   :433.00   Max.   :998.0  
      Tamb         WindVel          WindDir     
 Min.   :-1.0   Min.   : 0.000   Min.   :  0.0  
 1st Qu.:11.0   1st Qu.: 2.000   1st Qu.:190.0  
 Median :15.0   Median : 4.000   Median :270.0  
 Mean   :15.3   Mean   : 3.796   Mean   :230.8  
 3rd Qu.:19.0   3rd Qu.: 6.000   3rd Qu.:290.0  
 Max.   :38.0   Max.   :12.000   Max.   :360.0  
```
These look reasonable, but we don't know what GHI, DHI, DNI, Tamb, WindVel and WindDir are.

We can quickly examine the distributions of the Year, month, ..., minute
with
```{r}
par(mfrow=c(3, 2))
invisible(sapply(names(p2)[1:5], function(v) hist(p2[[v]], main = v, xlab = v)))
```
We see single values for each of Year and Minute.
Day is mostly uniform, but has few values for 29, 30 and 31.
We expect this.
While Hour is uniform, Month has a higher value for 1 (January). This is not expected so warrants
checking.


+ GHI - Global horizontal irradiance 
+ DNI - Direct normal irradiance.
+ DHI - Diffuse horizontal irradiance.
+ Tamb - Ambient temperature
+ WindVel - Wind velocit
+ WindDir - Wind direction


WindDir is the angle the wind comes from, so 0 to 360 is an appropriate range.
We note that it is not uniformly distributed with more coming from one quadrant.



### Defining the Function & Reading the Data
We define the function as
```{r}
readPVsyst = 
function(file)
{
	p2 = read.csv(file, skip = 14, header = FALSE)
	h = read.csv(file, skip = 12, nrow = 1, header = FALSE)
	names(p2) = h[1,]
	p2
}
```
(Make certain to return p2, not the names we set, i.e., we need the last line.


Next  we use the function to read the files and check the basic structure:
```{r}
pv = lapply(pv.files, readPVsyst)

sapply(pv, class)
sapply(pv, dim)
```

# Reading a .wea file

The start of a .wea file looks something like
```
place Bodega.Bay.CG.Light.Station_USA
latitude 38.31
longitude 123.05
time_zone 120
site_elevation 4.0
weather_data_file_units 1
1 1 1.000 0 0
1 1 2.000 0 0
1 1 3.000 0 0
```
We might assume that all of the .wea files have 6 lines of metadata and then the values.
However, we can verify this with

```{r}
weaFiles = list.files("ZIP/Files", pattern = ".wea", full = TRUE)
```

```{r}
tmp = lapply(weaFiles, readLines, n = 7)
```
We can visually inspect these to see they have the same structure, but different values
that are site-specific.

We can programmatically check the first line starts with place, the second with latitude, etc.
```{r}
expect = c("place", "latitude", "longitude", "time_zone", "site_elevation", 
           "weather_data_file_units")

all(sapply(tmp, function(x) all(substring(x[1:6], 1, nchar(expect))  == expect)))
```
This is TRUE so we have the same structure (and in the same order) in each file.


The first line of data appears to be the same for all files
```{r}
sapply(tmp, function(x) identical(x[7], tmp[[1]][7]))
```
Is this a coincidence or are the date the same for all the files?
We'll check when we have read the date.

The data from each file are straightforward to read by skipping the first 6 lines
and noting there are no columb names

```{r}
dd = lapply(weaFiles, read.table, sep = " ", header = FALSE, skip = 6)
```
We do a quick sanity check
```{r}
sapply(dd, nrow)
```
They each have 8760 rows.

Are they all the same
```{r}
identical(dd[[1]], dd[[2]])
```
No, so that allays our concerns from the first rows being the same.

To examine the values, we will stack these data frames along with the location
```{r}
wea = do.call(rbind, dd)
wea$location = rep(basename(weaFiles), sapply(dd, nrow))
```

Just to check we didn't mess anything up, let's count the number of rows for the different locations we have:
```{r}
table(wea$location)
```
```
USA_CA_Fairfield-San.Francisco.Bay.Reserve.998011_TMYx.2007-2021.wea 
                                                                8760 
        USA_CA_Marin.County.AP-Gnoss.Field.720406_TMYx.2007-2021.wea 
                                                                8760 
                     USA_CA_Napa.County.AP.724955_TMYx.2007-2021.wea 
                                                                8760 
             USA_CA_Point.Reyes.Lighthouse.724959_TMYx.2007-2021.wea 
                                                                8760 
             USA_CA_UC-Davis-University.AP.720576_TMYx.2007-2021.wea 
                                                                8760 
```



We define our function as
```{r}
readWEA =
function(file)
    read.table(file, sep = " ", header = FALSE, skip = 6)
```

Then we read the 5 WEA files and check the results for basic structure:
```{r}
wea = lapply(weaFiles, readWEA)
sapply(wea, class)
sapply(wea, dim)
```


