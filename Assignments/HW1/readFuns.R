readPVsyst = 
function(file)
{
    p2 = read.csv(file, skip = 14, header = FALSE)
    h = read.csv(file, skip = 12, nrow = 1, header = FALSE)
    names(p2) = h[1,]
    p2
}


readWEA =
function(file)
{
    read.table(file, sep = " ", header = FALSE, skip = 6)
}
