#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2010-2021 Mark Wong
# Copyright (C) 2014      2ndQuadrant, Ltd.
#

usage()
{
	echo "`basename $0` is the PostgreSQL database statistics chart generator"
	echo ""
	echo "Usage:"
	echo "  `basename $0` [OPTION]"
	echo ""
	echo "Options:"
	echo "  -i CSV      path to CSV file"
	echo "  -n DBNAME   database name"
	echo "  -o PATH     output directory"
}

while getopts "hi:n:o:" opt; do
	case $opt in
	h)
		usage
		exit 1
		;;
	i)
		CSVFILE=$OPTARG
		;;
	n)
		PGDATABASE=$OPTARG
		;;
	o)
		OUTDIR=$OPTARG
		mkdir -p $OUTDIR
		if [ ! -d "$OUTDIR" ]; then
			echo "ERROR: Failed to create directory $OUTDIR"
			exit 1
		fi
		;;
	\?)
		usage
		exit 1
		;;
	esac
done

if [ "x$CSVFILE" = "x" ]; then
	error "ERROR: input CSV file was not specified with -i"
	exit 1
fi

if [ "x$OUTDIR" = "x" ]; then
	error "ERROR: output directory was not specified with -o"
	exit 1
fi

if [ "x$PGDATABASE" = "x" ]; then
	echo "ERROR: PGDATABASE not set, use -n"
	exit 1
fi

R --slave --no-save << __EOF__
df <- read.csv("$CSVFILE", header=T)
df <- subset(df, df\$datname == "$PGDATABASE")
starttime = df[1,]\$ctime
df\$ctime <- (df\$ctime - starttime) / 60

# Calculate rate of change.

tmp <- c(NA, df\$xact_commit[-nrow(df)])
df\$xact_commit <- df\$xact_commit - tmp

tmp <- c(NA, df\$xact_rollback[-nrow(df)])
df\$xact_rollback <- df\$xact_rollback - tmp

tmp <- c(NA, df\$blks_read[-nrow(df)])
df\$blks_read <- df\$blks_read - tmp

tmp <- c(NA, df\$blks_hit[-nrow(df)])
df\$blks_hit <- df\$blks_hit - tmp

tmp <- c(NA, df\$tup_returned[-nrow(df)])
df\$tup_returned <- df\$tup_returned - tmp

tmp <- c(NA, df\$tup_fetched[-nrow(df)])
df\$tup_fetched <- df\$tup_fetched - tmp

tmp <- c(NA, df\$tup_inserted[-nrow(df)])
df\$tup_inserted <- df\$tup_inserted - tmp

tmp <- c(NA, df\$tup_updated[-nrow(df)])
df\$tup_updated <- df\$tup_updated - tmp

tmp <- c(NA, df\$tup_deleted[-nrow(df)])
df\$tup_deleted <- df\$tup_deleted - tmp

bitmap("$OUTDIR/db-stat-$PGDATABASE-connections.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$numbackends,  xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$numbackends)), type = "b", col = rainbow(1),
     main="Database $PGDATABASE Number of Backends",
     xlab="Elapsed Time (minutes)", ylab="Backends")
grid(col="gray")
invisible(dev.off())

color <- rainbow(2)
pch <- c(1, 2)

bitmap("$OUTDIR/db-stat-$PGDATABASE-xacts.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$xact_commit,  xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(max(df\$xact_commit, na.rm = T),
                   max(df\$xact_rollback, na.rm = T))),
     type = "b", col = color[1], main="Database $PGDATABASE Transactions",
     xlab="Elapsed Time (minutes)", ylab="Transactions", pch = pch[1])
points(df\$ctime, df\$xact_rollback, type = "b", pch = pch[2], col=color[2])
legend('topright', c("Commits", "Rollbacks"), pch = pch, col=color)
grid(col="gray")
invisible(dev.off())

bitmap("$OUTDIR/db-stat-$PGDATABASE-blocks.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$blks_read,  xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(max(df\$blks_read, na.rm = T),
                   max(df\$blks_hit, na.rm = T))),
     type = "b", col = color[1], main="Database $PGDATABASE Blocks",
     xlab="Elapsed Time (minutes)", ylab="Blocks", pch = pch[1])
points(df\$ctime, df\$blks_hit, type = "b", pch = pch[2], col=color[2])
legend('topright', c("Read", "Hit"), pch = pch, col=color)
grid(col="gray")
invisible(dev.off())
__EOF__
