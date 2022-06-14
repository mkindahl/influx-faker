library('RPostgreSQL')
library(ggplot2)

DB <- Sys.getenv("PGDATABASE")
HOST <- Sys.getenv("PGHOST")
PORT <- Sys.getenv("PGPORT")

pg = dbDriver("PostgreSQL")
con = dbConnect(pg, dbname=DB, host=HOST, port=PORT)
table = dbGetQuery(con, "SELECT * FROM measurements")

ggplot(table, aes(x=as.factor(version), y=count)) + 
    geom_boxplot(fill="slateblue", alpha=0.2) + 
    xlab("version")
ggsave("count-boxplot.png")

ggplot(table, aes(x=version, y=count, fill=version)) + geom_violin()
ggsave("count-violin.png")
