#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2014      2ndQuadrant, Ltd.
#               2010-2022 Mark Wong
#
if [ $# -lt 6 ]; then
	echo "$(basename $0) is the DBT transaction rate plotter"
	echo ""
	echo "Usage:"
	echo "  $(basename $0) <txn name> <txn id> <rate> <output directory> <color index> <log0> [log1 [...]]"
	echo ""
	echo "Options"
	echo "  txn name            name to use on the chart title"
	echo "  txn id              identifier used in the log file"
	echo "  rate                tps or tpm"
	echo "  output directory    path to output charts"
	echo "  color index         number for selecting plot color"
	echo "  log                 log file to load"
	exit 1
fi

TXN_NAME=$1
shift
TXN_TAG=$1
shift
RATE=$1
shift
OUTPUTDIR=$1
shift
COLOR=$1
shift

mkdir -p $OUTPUTDIR
if [ ! -d "${OUTPUTDIR}" ]; then
	echo "ERROR: Failed to create directory ${OUTPUTDIR}"
	exit 1
fi

if [ "x${RATE}" = "xtpm" ]; then
	YLABEL="Minute"
	TIMEFACTOR=1
elif [ "x${RATE}" = "xtps" ]; then
	YLABEL="Second"
	TIMEFACTOR=60
else
	echo "ERROR: unknown rate ${RATE}"
	exit 1
fi

# Covert the list of file names from the command line into a quoted and comma
# separated list for R.
FILENAMES=""
for FILENAME in $@; do
	FILENAMES="$FILENAMES \"$FILENAME\""
done
FILENAMES=$(echo $FILENAMES | sed -e "s/ /,/g")

R --slave --no-save << __EOF__
filenames <- c(${FILENAMES})
df <- do.call(rbind, lapply(filenames, read.csv, header=FALSE))
colnames(df)[1] <- 'ctime'
colnames(df)[2] <- 'txn'
# This is really the transaction "status" column, but we're going to count the
# number of occurrences here.
colnames(df)[3] <- 'count'

color <- rainbow(length(unique(df\$txn[df\$txn != "START" &
                                       df\$txn != "TERMINATED"])))

# Convert ctime to elapsed time and filter for specific transaction to plot.
starttime = df[1,]\$ctime
df\$ctime <- ceiling((df\$ctime - starttime) / 60)
df <- df[order(df\$ctime, decreasing=FALSE) & df\$txn == "${TXN_TAG}",]

# Aggregate counts and convert to desired rate.
df <- aggregate(count ~ txn + ctime, df, length)
df\$count <- df\$count / $TIMEFACTOR

bitmap("${OUTPUTDIR}/t${TXN_TAG}-transaction-rate.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$count, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$count)), type = "b", col = color[${COLOR}],
     main="$TXN_NAME Transaction Rate",
     xlab="Elapsed Time (minutes)", ylab="Transaction per ${YLABEL}")
grid(col="gray")
invisible(dev.off())
__EOF__
