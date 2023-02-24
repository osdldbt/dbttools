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
	echo "`basename $0` is the PostgreSQL table statistics chart generator"
	echo ""
	echo "Usage:"
	echo "  `basename $0` [OPTION]"
	echo ""
	echo "Options:"
	echo "  -i CSV      path to CSV file"
	echo "  -n TABLE    table name"
	echo "  -o PATH     output directory"
}

error() {
	echo "ERROR: $@"
	exit 1
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
		TABLENAME=$OPTARG
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
	error "input CSV file was not specified with -i"
fi

if [ "x$OUTDIR" = "x" ]; then
	error "output directory was not specified with -o"
fi

if [ "x$TABLENAME" = "x" ]; then
	error "table name not set, use -n"
fi

R --slave --no-save << __EOF__
df <- read.csv("$CSVFILE", header=T)
df <- subset(df, df\$relname == "${TABLENAME}")
starttime = df[1,]\$ctime
df\$ctime <- (df\$ctime - starttime) / 60

# Calculate rate of change.

tmp <- c(NA, df\$seq_scan[-nrow(df)])
df\$seq_scan <- df\$seq_scan - tmp

tmp <- c(NA, df\$idx_scan[-nrow(df)])
df\$idx_scan <- df\$idx_scan - tmp

tmp <- c(NA, df\$seq_tup_read[-nrow(df)])
df\$seq_tup_read <- df\$seq_tup_read - tmp

tmp <- c(NA, df\$idx_tup_fetch[-nrow(df)])
df\$idx_tup_fetch <- df\$idx_tup_fetch - tmp

tmp <- c(NA, df\$n_tup_ins[-nrow(df)])
df\$n_tup_ins <- df\$n_tup_ins - tmp

tmp <- c(NA, df\$n_tup_upd[-nrow(df)])
df\$n_tup_upd <- df\$n_tup_upd - tmp

tmp <- c(NA, df\$n_tup_del[-nrow(df)])
df\$n_tup_del <- df\$n_tup_del - tmp

tmp <- c(NA, df\$n_tup_hot_upd[-nrow(df)])
df\$n_tup_hot_upd <- df\$n_tup_hot_upd - tmp

#tmp <- c(NA, df\$n_live_tup[-nrow(df)])
#df\$n_live_tup <- df\$n_live_tup - tmp

#tmp <- c(NA, df\$n_dead_tup[-nrow(df)])
#df\$n_dead_tup <- df\$n_dead_tup - tmp

tmp <- c(NA, df\$heap_blks_read[-nrow(df)])
df\$heap_blks_read <- df\$heap_blks_read - tmp

tmp <- c(NA, df\$heap_blks_hit[-nrow(df)])
df\$heap_blks_hit <- df\$heap_blks_hit - tmp

tmp <- c(NA, df\$idx_blks_read[-nrow(df)])
df\$idx_blks_read <- df\$idx_blks_read - tmp

tmp <- c(NA, df\$idx_blks_hit[-nrow(df)])
df\$idx_blks_hit <- df\$idx_blks_hit - tmp

tmp <- c(NA, df\$toast_blks_read[-nrow(df)])
df\$toast_blks_read <- df\$toast_blks_read - tmp

tmp <- c(NA, df\$toast_blks_hit[-nrow(df)])
df\$toast_blks_hit <- df\$toast_blks_hit - tmp

tmp <- c(NA, df\$tidx_blks_read[-nrow(df)])
df\$tidx_blks_read <- df\$tidx_blks_read - tmp

tmp <- c(NA, df\$tidx_blks_hit[-nrow(df)])
df\$tidx_blks_hit <- df\$tidx_blks_hit - tmp

bitmap("${OUTDIR}/table-stat-${TABLENAME}-seq_scan.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$seq_scan, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$seq_scan, na.rm = T)), type = "b", col = rainbow(1),
     main="Sequential Scans (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Sequential Scans")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-seq_tup_read.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$seq_tup_read, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$seq_tup_read, na.rm = T)), type = "b",
     col = rainbow(1), main="Tuples Read by Sequential Scan (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Tuples")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-idx_scan.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$idx_scan, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$idx_scan, na.rm = T)), type = "b", col = rainbow(1),
     main="Index Scans (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Index Scans")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-idx_tup_fetch.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$idx_tup_fetch, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$idx_tup_fetch, na.rm = T)), type = "b",
     col = rainbow(1), main="Tuples Read by Index Scans (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Tuples")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-n_tup_ins.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$n_tup_ins, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$n_tup_ins, na.rm = T)), type = "b", col = rainbow(1),
     main="Inserts (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Tuples")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-n_tup_upd.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$n_tup_upd, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$n_tup_upd, na.rm = T)), type = "b", col = rainbow(1),
     main="Updates (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Tuples")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-n_tup_del.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$n_tup_del, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$n_tup_del, na.rm = T)), type = "b", col = rainbow(1),
     main="Deletes (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Tuples")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-n_tup_hot_upd.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$n_tup_hot_upd, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$n_tup_hot_upd, na.rm = T)), type = "b",
     col = rainbow(1), main="HOT Updates (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Tuples")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-n_live_tup.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$n_live_tup, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$n_live_tup, na.rm = T)), type = "b", col = rainbow(1),
     main="Live Rows (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Tuples")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-n_dead_tup.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$n_dead_tup, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$n_dead_tup, na.rm = T)), type = "b", col = rainbow(1),
     main="Estimated Number of Dead Rows (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Tuples")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-heap_blks_read.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$heap_blks_read, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$heap_blks_read, na.rm = T)), type = "b",
     col = rainbow(1), main="Heap Blocks Read (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Blocks")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-heap_blks_hit.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$heap_blks_hit, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$heap_blks_hit, na.rm = T)), type = "b",
     col = rainbow(1), main="Heap Blocks Hit (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Blocks")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-idx_blks_read.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$idx_blks_read, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$idx_blks_read, na.rm = T)), type = "b",
     col = rainbow(1), main="Index Blocks Read (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Blocks")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-idx_blks_hit.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$idx_blks_hit, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$idx_blks_hit, na.rm = T)), type = "b",
     col = rainbow(1), main="Index Blocks Hit (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Blocks")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-toast_blks_read.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$toast_blks_read, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$toast_blks_read, na.rm = T)), type = "b",
     col = rainbow(1), main="Toast Blocks Read (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Blocks")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-toast_blks_hit.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$toast_blks_hit, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$toast_blks_hit, na.rm = T)), type = "b",
     col = rainbow(1), main="Toast Blocks Hit (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Blocks")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-tidx_blks_read.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$tidx_read, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$tidx_read, na.rm = T)), type = "b",
     col = rainbow(1), main="Toast Index Blocks Read (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Blocks")
grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/table-stat-${TABLENAME}-tidx_blks_hit.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$tidx_blks_hit, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$tidx_blks_hit, na.rm = T)), type = "b",
     col = rainbow(1), main="Toast Index Blocks Hit (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Blocks")
grid(col="gray")
invisible(dev.off())

# Group plots

color = rainbow(2)
pch <- c(1, 2)

bitmap("${OUTDIR}/table-stat-${TABLENAME}-scans.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$seq_scan, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(max(df\$seq_scan, na.rm = T),
                   max(df\$idx_scan, na.rm = T))),
     type = "b", col = rainbow(1), main="Scans on ${TABLENAME}",
     xlab="Elapsed Time (minutes)", ylab="Number of Scans")
points(df\$ctime, df\$idx_scan, type = "b", pch = pch[2], col=color[2])
legend('topright', c("Table Scans", "Index Scans"), pch = pch, col=color)
grid(col="gray")
invisible(dev.off())

color = rainbow(6)
pch <- c(1, 6)

bitmap("${OUTDIR}/table-stat-${TABLENAME}-tup.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$seq_tup_read, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(max(df\$seq_tup_read, na.rm = T),
                   max(df\$idx_tup_fetch, na.rm = T),
                   max(df\$n_tup_ins, na.rm = T),
                   max(df\$n_tup_upd, na.rm = T),
                   max(df\$n_tup_del, na.rm = T),
                   max(df\$n_tup_hot_upd, na.rm = T))),
     type = "b", col = rainbow(1),
     main="Tuples (${TABLENAME})",
     xlab="Elapsed Time (minutes)", ylab="Tuples")
points(df\$ctime, df\$idx_tup_fetch, type = "b", pch = pch[2], col=color[2])
points(df\$ctime, df\$n_tup_ins, type = "b", pch = pch[3], col=color[3])
points(df\$ctime, df\$n_tup_upd, type = "b", pch = pch[4], col=color[4])
points(df\$ctime, df\$n_tup_del, type = "b", pch = pch[5], col=color[5])
points(df\$ctime, df\$n_tup_hot_upd, type = "b", pch = pch[6], col=color[6])
legend('topright', c("Sequential Scans", "Index Scans", "Inserts", "Updates",
                     "Deletes", "HOT Updates"), pch = pch, col=color)
grid(col="gray")
invisible(dev.off())
__EOF__
