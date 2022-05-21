library('RPostgreSQL')
library(ggplot2)

pg = dbDriver("PostgreSQL")
con = dbConnect(pg, dbname="influx", host="localhost", port=5432)
table = dbGetQuery(con, "SELECT * FROM measurements")
ggplot(table, aes(x=as.factor(version), y=count)) + 
    geom_boxplot(fill="slateblue", alpha=0.2) + 
    xlab("version")
ggsave("count-boxplot.png")

ggplot(table, aes(x=version, y=count, fill=version)) + geom_violin()
ggsave("count-violin.png")
