#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright The DBT Tools Authors
#

if [ $# -lt 5 ]; then
	echo "$(basename $0) is the DBT transaction distribution plotter"
	echo ""
	echo "Usage:"
	echo "  $(basename $0) <txn name> <txn id> <output directory> <color index> <log0> [log1 [...]]"
	echo ""
	echo "Options"
	echo "  txn name            name to use on the chart title"
	echo "  txn id              identifer used in the log file"
	echo "  output directory    path to output charts"
	echo "  color index         number for selecting plot color"
	echo "  log                 log file to load"
	exit 1
fi

TXN_NAME=$1
shift
TXN_TAG=$1
shift
OUTPUTDIR=$1
shift
COLOR=$1
shift

mkdir -p ${OUTPUTDIR}
if [ ! -d "${OUTPUTDIR}" ]; then
	echo "Failed to create directory ${OUTPUTDIR}"
	exit 1
fi

# Covert the list of file names from the comand line into a quoted and comma
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
colnames(df)[4] <- 'response'

# This will generate color options for markers in the mix log, manually
# compendate.
color <- rainbow(length(unique(df\$txn)) - 2)

df <- subset(df, df\$txn == "${TXN_TAG}")

# Convert ctime to elapsed time in minutes
starttime = df[1,]\$ctime
df\$ctime <- (df\$ctime - starttime) / 60

bitmap("${OUTPUTDIR}/t${TXN_TAG}-distribution.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$ctime, df\$response,  xlim=c(0, max(df\$ctime)),
     ylim=c(0, max(df\$response)), type = "p", col = color[${COLOR}],
     main="${TXN_NAME} Transaction Response Time Distribution",
     xlab="Elapsed Time (minutes)", ylab="Response Time (seconds)")
grid(col="gray")
invisible(dev.off())
__EOF__
