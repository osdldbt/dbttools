#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2015      2ndQuadrant, Ltd.
#               2015-2022 Mark Wong
#

usage()
{
	echo "`basename $0` is the DBT pidstat plotter"
	echo ""
	echo "Usage:"
	echo "  `basename $0` [OPTIONS]"
	echo ""
	echo "General options:"
	echo "  -c COMMAND    command string to match"
	echo "  -i FILE       pidstat.csv file"
	echo "  -m METRIC     metric to plot"
	echo "  -i PATH       output directory, default ./"
	echo "  -t TAG        tag to use for chart filenames"
}

OUTDIR="."
while getopts "c:hi:m:o:t:" opt; do
	case $opt in
	c)
		COMMAND=$OPTARG
		;;
	h)
		usage
		exit 1
		;;
	i)
		INPUTFILE=$OPTARG
		;;
	m)
		METRIC=$OPTARG
		;;
	o)
		OUTDIR=$OPTARG
		if [ ! -d "$OUTDIR" ]; then
			mkdir -p $OUTDIR
		fi
		;;
	t)
		TAG="-${OPTARG}"
		;;
	esac
done

if [ "x${INPUTFILE}" = "x" ]; then
	echo "ERROR: use -i to specify pidstat csv file"
	exit 1
fi

if [ ! -f "$INPUTFILE" ]; then
	echo "ERROR: file does not exist $INPUTFILE"
	exit 1
fi

if [ "x${METRIC}" = "x" ]; then
	echo "ERROR: use -m to specify metric to plot"
	exit 1
fi

if [ "x${COMMAND}" = "x" ]; then
	echo "ERROR: use -c to specify command to plot"
	exit 1
fi

R --slave --no-save << __EOF__
df <- read.csv("$INPUTFILE", header=T)

# pidstat doesn't provide a way to not break up commands into multiple lines.
# If a command is broken up into multiple lines, do the easiest thing, drop all
# rows that don't obvious have the time in the first column.
df <- subset(df, !is.na(as.integer(df\$Time)))

# And when that happens we have to covert columns back to numbers because R
# converts column data to strings if there are mixed types.
df\$Time <- as.integer(df\$Time)
df\$$METRIC <- as.numeric(df\$$METRIC)

starttime = df[1,]\$Time
df\$Time <- ceiling((df\$Time - starttime) / 60)

df.all <- subset(df, grepl("$COMMAND", df\$Command))

pids <- sort(unique(df.all\$PID))
count <- length(pids)
color <- rainbow(count)
pch <- seq.int(1, count)

bitmap("${OUTDIR}/pidstat${TAG}-${METRIC}.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)

df.pid <- subset(df.all, PID == pids[1])
plot(df.pid\$Time, df.pid\$$METRIC,
     xlim=c(0, max(df.all\$Time, na.rm=T)),
     ylim=c(0, max(df.all\$$METRIC, na.rm=T)), type="b", col=color[1],
     main="pidstat $METRIC $COMMAND",
     xlab="Elapsed Time (minutes)", ylab="$METRIC")

for (i in 2:count) {
  df.pid <- subset(df.all, PID == pids[i])
  points(df.pid\$Time, df.pid\$$METRIC, type = "b", pch=pch[i], col=color[i])
}

legend('topright', sapply(pids, as.character), pch=pch, col=color, title='PID')

grid(col="gray")
invisible(dev.off())
__EOF__
