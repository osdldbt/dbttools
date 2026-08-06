#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright The DBT Tools Authors
#

if [ $# -lt 6 ]; then
	echo "$(basename "$0") is the DBT transaction rate plotter"
	echo ""
	echo "Usage:"
	echo "  $(basename "$0") <txn name> <txn id> <rate> <output directory> <color index> <log0> [log1 [...]]"
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

mkdir -p "${OUTPUTDIR}"
if [ ! -d "${OUTPUTDIR}" ]; then
	echo "ERROR: Failed to create directory ${OUTPUTDIR}"
	exit 1
fi

if [ "${RATE}" = "tpm" ]; then
	YLABEL="Minute"
elif [ "${RATE}" = "tps" ]; then
	YLABEL="Second"
else
	echo "ERROR: unknown rate ${RATE}"
	exit 1
fi

# Convert the list of file names from the command line into a quoted and
# comma separated list for R.
FILENAMES=""
for FILENAME in "$@"; do
	FILENAMES="${FILENAMES},\"${FILENAME}\""
done
FILENAMES="${FILENAMES#,}"

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

# Convert ctime to elapsed time, using the earliest event in the logs as
# time zero, and filter for specific transaction to plot.
starttime <- min(df\$ctime)
duration <- max(df\$ctime) - starttime + 1
df\$ctime <- floor((df\$ctime - starttime) / 60)
df <- df[df\$txn == "${TXN_TAG}",]

# Aggregate counts per minute; for tps, average each minute over the
# seconds it actually covers.  na.pass keeps rows whose status column is
# NA, which the formula interface would otherwise drop before counting.
df <- aggregate(count ~ txn + ctime, df, length, na.action = na.pass)
if ("${RATE}" == "tps") {
    df\$count <- df\$count / pmin(60, duration - df\$ctime * 60)
}

bitmap("${OUTPUTDIR}/t${TXN_TAG}-transaction-rate.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$count, xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$count)), type = "b", col = color[${COLOR}],
     main="$TXN_NAME Transaction Rate",
     xlab="Elapsed Time (minutes)", ylab="Transactions per ${YLABEL}")
grid(col="gray")
invisible(dev.off())
__EOF__
