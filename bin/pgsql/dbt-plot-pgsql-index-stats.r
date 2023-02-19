#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2014      2ndQuadrant, Ltd.
#               2010-2022 Mark Wong
#

usage()
{
	echo "`basename $0` is the PostgreSQL index statistics chart generator"
	echo ""
	echo "Usage:"
	echo "  `basename $0` [OPTION]"
	echo ""
	echo "Options:"
	echo "  -i CSV      path to CSV file"
	echo "  -n INDEX    index name"
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
		INDEXNAME=$OPTARG
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

if [ "x$INDEXNAME" = "x" ]; then
	echo "ERROR: index name not set, use -n"
	exit 1
fi

R --slave --no-save << __EOF__
df <- read.csv("$CSVFILE", header=T)
df <- subset(df, df\$indexrelname == "${INDEXNAME}")
starttime = df[1,]\$ctime
df\$ctime <- (df\$ctime - starttime) / 60

# Calculate rate of change.

tmp <- c(NA, df\$idx_scan[-nrow(df)])
df\$idx_scan <- df\$idx_scan - tmp

tmp <- c(NA, df\$idx_tup_read[-nrow(df)])
df\$idx_tup_read <- df\$idx_tup_read - tmp

tmp <- c(NA, df\$idx_tup_fetch[-nrow(df)])
df\$idx_tup_fetch <- df\$idx_tup_fetch - tmp

tmp <- c(NA, df\$idx_blks_read[-nrow(df)])
df\$idx_blks_read <- df\$idx_blks_read - tmp

tmp <- c(NA, df\$idx_blks_hit[-nrow(df)])
df\$idx_blks_hit <- df\$idx_blks_hit - tmp

bitmap("${OUTDIR}/index-stat-${INDEXNAME}-idx_scan.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$idx_scan, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$idx_scan, na.rm = T)), type = "b", col = rainbow(1),
     main="Index Scans (${INDEXNAME})",
     xlab="Elapsed Time (minutes)", ylab="Scans")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/index-stat-${INDEXNAME}-idx_tup_read.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$idx_tup_read, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$idx_tup_read, na.rm = T)), type = "b",
     col = rainbow(1), main="Tuples Read (${INDEXNAME})",
     xlab="Elapsed Time (minutes)", ylab="Tuples")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/index-stat-${INDEXNAME}-idx_tup_fetch.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$idx_tup_fetch, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$idx_tup_fetch, na.rm = T)), type = "b",
     col = rainbow(1), main="Tuples Fetched (${INDEXNAME})",
     xlab="Elapsed Time (minutes)", ylab="Tuples")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/index-stat-${INDEXNAME}-idx_blks_read.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$idx_blks_read, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$idx_blks_read, na.rm = T)), type = "b",
     col = rainbow(1), main="Index Blocks Read (${INDEXNAME})",
     xlab="Elapsed Time (minutes)", ylab="Blocks")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/index-stat-${INDEXNAME}-idx_blks_hit.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$idx_blks_hit, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$idx_blks_hit, na.rm = T)), type = "b",
     col = rainbow(1), main="Index Blocks Hit (${INDEXNAME})",
     xlab="Elapsed Time (minutes)", ylab="Tuples")
grid(col="gray")
invisible(dev.off())

# Groups

color <- rainbow(2)
pch <- c(1, 2)

bitmap("${OUTDIR}/index-stat-${INDEXNAME}-idx_blks.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$idx_blks_read, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(max(df\$idx_blks_read, na.rm = T),
                   max(df\$idx_blks_hit, na.rm = T))),
     type = "b", col = rainbow(1), main="Index Blocks (${INDEXNAME})",
     xlab="Elapsed Time (minutes)", ylab="Blocks")
points(df\$ctime, df\$idx_blks_hit, type = "b", pch = pch[2], col=color[2])
legend('topright', c("Read", "Hit"), pch = pch, col=color)
grid(col="gray")
invisible(dev.off())
__EOF__
exit 0
