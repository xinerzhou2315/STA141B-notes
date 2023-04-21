# Reading a .clm File

The top of a .clm file looks something like
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
```
The lines col 1, col 2, ... provide the descriptions of the variables.


While we also want the metadata, we'll focus on the values.
These are the rows after the 
```
* day <num> month <num>
```
lines. We only see one of these but there are more.


```{r}
f = "USA_CA_Bodega.Bay.CG.Light.Station.724995_TMYx.clm"
z = read.csv(f, skip = 13, header = FALSE)
```
We get no error or warnings.
How did it deal with the change in the month?
```{r}
head(z, 30)
```
```
                  V1  V2  V3 V4  V5  V6
1                  0  75   0 11 329  92
2                  0  72   0 20 338  91
3                  0  75   0 13 341  93
4                  0  61   0 13 338  95
5                  0  57   0 15 335  94
6                  0  65   0 25 348  93
7                  0  64   0  6  24  94
8                 28  58 182 15  23  95
9                 68  67 455 14   1  93
10               112  76 522 16  81  90
11               157  94 465 22 122  78
12               178 117 439 21 143  73
13               160 122 498 17 160  83
14               129 118 507 19 175  88
15               100 116 382 22 181  89
16                54 116 256 23 219  91
17                13 107   0 20 235  91
18                 0  97   0  9 192  96
19                 0 106   0 10 183  97
20                 0 108   0 15 190  96
21                 0 106   0 16 181  97
22                 0 104   0 16 126  99
23                 0 102   0 19 119 100
24                 0  97   0 26 126 100
25 * day  2 month  1  NA  NA NA  NA  NA
26                 0  97   0 19 129 100
27                 0  98   0 18 129 100
28                 0  98   0 17 121 100
29                 0  98   0 19 119  99
30                 0  99   0 21 110  99
```
So the `* day ...` was absorbed into the first column and the remaining columns were filled with NA
values.

This causes the first column to be treated as a character vector since not all
values are numbers.

We can identify these rows and remove them and then convert the 
column to numbers.

```{r}
i = grep("day", z[[1]])
z = z[-i,]
z[[1]] = as.integer(z[[1]])
sapply(z, class)
```

We can also filter the values out in the call to read.table.
We can change what read.table considers a comment character to *
```{r}
z2 = read.csv(f, skip = 13, header = FALSE, comment.char = "*")
sapply(z2, class)
head(z2, 33)
```


While these two approaches allow us to obtain a data.frame,
we have lost the day and month information.
We need to add two columns

There are various approaches we could use, but each relies
on identifying the row identifying the start of a new month.

```{r}
ll = readLines(f)
ll = ll[-(1:13)]
```

```{r}
isDay = substring(ll, 1, 5) == "* day"
```

```
group = cumsum(isDay)
blocks = split(ll, group)
month.dfs = lapply(blocks, function(x) read.csv(textConnection(x[-1]), header = FALSE))
```

```{r}
clm = do.call(rbind, month.dfs)
```

We can add the day and month to the entire data.frame, but it may be simpler to do this when
creating each sub-data.frame, i.e., when processing a block.
The first line in each block is of the form
```{r}
"* day 25 month 12"
```
We'll separate this by space and exract the third and fifth elements.
Then we can repeat these
```{r}
procCLMBlock = 
function(x) 
{
   df = read.csv(textConnection(x[-1]), header = FALSE)
   els = strsplit(x[1], " ")[[1]]
   df$day = as.integer(els[3])
   df$month = as.integer(els[5])
   df
}
```
```{r}
month.dfs = lapply(blocks, procCLMBlock)
```
But this doesn't quite work.
We get warnings
```
Warning in FUN(X[[i]], ...) : NAs introduced by coercion
```
We might think there are NA values in the actual data and ignore these.
However, we should investigate, especially since we know from earlier
when we skipped the `* day` lines, there were no NAs.

I set 
```{r}
options(error = recover, warn = 2)
```
to stop in the debugger/recover function when a warning occurs.

```{r}
procCLMBlock(blocks[[1]])
```
There is no error/warning.


Let's try the second block.
```{r}
procCLMBlock(blocks[[1]])
```
```
Error in procCLMBlock(blocks[[2]]) : 
  (converted from warning) NAs introduced by coercion

Enter a frame number, or 0 to exit   

1: procCLMBlock(blocks[[2]])
2: #6: .signalSimpleWarning("NAs introduced by coercion", base::quote(procCLMBlock(blocks[[2]])))
3: withRestarts({
    .Internal(.signalCondition(simpleWarning(msg, call), msg, call))
    .Internal(.dfltWarn(msg, call))
}, muffleWarning = function(
4: withOneRestart(expr, restarts[[1]])
5: doWithOneRestart(return(expr), restart)

Selection: 
```
We select frame 1 and use ls() to find what variables are available.
```
[1] "df"  "els" "x"  
```
We look at els since this is the new object we introduced most recently.
```
[1] "*"     "day"   ""      "2"     "month" ""      "1"    
```
Here is our problem - the third element is "" not the "2".
Similarly "month" and "1" are separated by "".
This is presumably (assumption) because these are single digit numbers.
When we get to a day with 2 digits, this won't happen for the day, and
similarly for the month.

We can fix this by using a regular expression in the call to `strsplit()`,
but we haven't covered these at this point in the course.
So we just remove "" entries and then the third and fifth elements will be as we expect.
```{r}
procCLMBlock = 
function(x) 
{
   df = read.csv(textConnection(x[-1]), header = FALSE)
   els = strsplit(x[1], " ")[[1]]
   els = els[els != ""]
   df$day = as.integer(els[3])
   df$month = as.integer(els[5])
   df
}
```

We check to see if we get an error/warning:
```{r}
procCLMBlock(blocks[[2]])
```
So things seem good.

```{r}
dfs = lapply(blocks, procCLMBlock)
clm = do.call(rbind, dfs)
```

Now we need to verify the results
```{r}
head(clm)
```
```
    V1 V2 V3 V4  V5 V6 month day
0.1  0 72  0 20 338 91    NA  NA
0.2  0 75  0 13 341 93    NA  NA
0.3  0 61  0 13 338 95    NA  NA
0.4  0 57  0 15 335 94    NA  NA
0.5  0 65  0 25 348 93    NA  NA
0.6  0 64  0  6  24 94    NA  NA
```
Immediately we have a problem with NA values for month and day.

How many do we have
```{r}
table(is.na(clm$month))
table(is.na(clm$day))
table(is.na(clm$month), is.na(clm$day))
```
```
        FALSE TRUE
  FALSE  8736    0
  TRUE      0   23
```

Where are they located, i.e., which rows
```{r}
which(is.na(clm$month))
```
```
 [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23
```
Note also that the values in the first row don't correspond to the first row of values in the file
(see above)
```
 0,75,0,11,329,92
```
The problem is we skipped the first 13 lines which included the first `* day  1 month  1` line.
Our function `procCLMBlock` assumed the first line was the day-month identifier and omitted that
in the call to `read.csv()` and used it for the day-month and it was in the wrong format.

So the fix is to not skip that first day-month line.
We can write a `readCLM` function as 
```{r}
readCLM = 
function(f)
{
	ll = readLines(f)
	ll = ll[-(1:12)]
	isDay = substring(ll, 1, 5) == "* day"	
	tmp = tapply(ll, cumsum(isDay), procCLMBlock)
	do.call(rbind, tmp)
}
```
Note we use `tapply()` rather than `split()` followed by `lapply()`.

```{r}
clm.files = list.files("ZIP/Files", pattern = ".clm", full = TRUE)
clms = lapply(clm.files, readCLM)
names(clms) = basename(clm.files)
```
We got no error(s) or warnings.
However, we now have to check the values are correct.

We can check the day values range from 1 to 12 at most
and the day values range from 1 to 31.


We can also stack the 5 data.frames together
and compare the distributions for each of the different variables across the different locations.
Before we do this, we should verify 

+ the data frames have the same number of columns
+ the variables in each clm file are the same.

```{r}
sapply(clms, ncol)
table(sapply(clms, ncol))
```
Indeed, they all have 8 columns.


To get the descriptions of the variables, we can read the file
and find the lines starting with `# col`
```{r}
descs = lapply(clm.files, function(f) grep("# col", readLines(f), value = TRUE))
```
```{r}
descs[[1]]
```
```
[1] "# col 1: Diffuse solar on the horizontal (W/m**2)"       "# col 2: External dry bulb temperature   (Tenths DEG.C)"
[3] "# col 3: Direct normal solar intensity   (W/m**2)"       "# col 4: Prevailing wind speed           (Tenths m/s)"  
[5] "# col 5: Wind direction     (clockwise deg from north)"  "# col 6: Relative humidity               (Percent)"     
```

Are they all the same? We can check they are all the same as the first one:
```{r}
sapply(descs[-1], identical, descs[[1]])
```
So they are all the same.


We can stack the data.frames with 
```{r}
zz = do.call(rbind, clms)
zz$location = rep(names(clms), sapply(clms, nrow))
```

To make the names of the locations shorter for plots, etc., 
we'll use a regular expression to transform them.
```{r}
tmp = gsub("USA_CA_([^0-9]+)(\\.AP)?\\.[0-9].+", "\\1", names(clms))
zz$location = rep(tmp, sapply(clms, nrow))
```

We can compare the density of values for V1
```{r}
ggplot( zz, aes(x = V1, color = location)) + geom_density()
```

Of course, the fact that these are similar doesn't mean they are correct.
There could be a bug in our code that makes each location incorrect.


We can check an individual value, say in 
ZIP/Files/USA_CA_Napa.County.AP.724955_TMYx.2007-2021.clm
for the third value from on day 4 of month 11.

```{r}
z = clms[["USA_CA_Napa.County.AP.724955_TMYx.2007-2021.clm"]]
z[z$day == 4 & z$month == 11,][3,]
```
```
4.3  0 133  0 62 190 93     1   4
```
This corresponds to line 7691 of the file
where we have 
```
 0,33,0,21,120,79
```

(Note that when I first did this check, the results did not match.
I had to figure out what was wrong.
It was simply that I had 
```{r}
z[z$day == 4 & z$month == 1,][3,]
```
The month is 1 not 11.
)

Checking one line doesn't guarantee the rest are correct.



We want to put the names of the 6 variables on the data.frame(s).
Again, we'll use regular expressions which we haven't covered yet.

In `descs[[1]]` above, we found the lines starting with `"# col"`.
These look like
```
# col 1: Diffuse solar on the horizontal (W/m**2)
# col 2: External dry bulb temperature   (Tenths DEG.C)
# col 3: Direct normal solar intensity   (W/m**2)
# col 4: Prevailing wind speed           (Tenths m/s)
# col 5: Wind direction     (clockwise deg from north)
# col 6: Relative humidity               (Percent)
```
We want the text after the : but not including the parenthetical part - the units.
```{r}
a = gsub("# col [0-9]: ", "", descs[[1]])
b = gsub("\\(.*", "", a)
names(zz)[1:length(b)] = trimws(b)
```
