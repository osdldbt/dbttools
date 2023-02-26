#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright The DBT Tools Authors
#

usage()
{
	echo "`basename $0` is the DBT sar memory statistics chart generator"
	echo ""
	echo "Usage:"
	echo "  `basename $0` [OPTION]"
	echo ""
	echo "Options:"
	echo "  -i CSV      path to sar-mem.csv file"
	echo "  -o PATH     output directory"
}

while getopts "hi:n:o:" opt; do
	case $opt in
	h)
		usage
		exit 1
		;;
	i)
		INPUTFILE=$OPTARG
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

if [ "x$INPUTFILE" = "x" ]; then
	error "ERROR: input CSV file was not specified with -i"
	exit 1
fi

if [ "x$OUTDIR" = "x" ]; then
	error "ERROR: output directory was not specified with -o"
	exit 1
fi

R --slave --no-save << __EOF__
df <- read.csv("$INPUTFILE", sep=";", header=T)
starttime = df[1,]\$timestamp
df\$timestamp <- ceiling((df\$timestamp - starttime) / 60)

bitmap("${OUTDIR}/sar-mem-kbbuffers.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$timestamp, df\$kbbuffers,
     xlim=c(0, max(df\$timestamp, na.rm=T)),
     ylim=c(0, max(df\$kbbuffers, na.rm=T)), type = "b", col = rainbow(1),
     main="Buffered Kernel Memory",
     xlab="Elapsed Time (minutes)", ylab="Kilobytes")

grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/sar-mem-kbcached.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$timestamp, df\$kbcached,
     xlim=c(0, max(df\$timestamp, na.rm=T)),
     ylim=c(0, max(df\$kbcached, na.rm=T)), type = "b", col = rainbow(1),
     main="Cached Kernel Memory",
     xlab="Elapsed Time (minutes)", ylab="Kilobytes")

grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/sar-mem-kbdirty.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$timestamp, df\$kbdirty,
     xlim=c(0, max(df\$timestamp, na.rm=T)),
     ylim=c(0, max(df\$kbdirty, na.rm=T)), type = "b", col = rainbow(1),
     main="Dirty Memory",
     xlab="Elapsed Time (minutes)", ylab="Kilobytes")

grid(col="gray")
invisible(dev.off())

bitmap("${OUTDIR}/sar-mem-memused.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$timestamp, df\$X.memused,
     xlim=c(0, max(df\$timestamp, na.rm=T)),
     ylim=c(0, 100), type = "b", col = rainbow(1),
     main="Memory Utilization",
     xlab="Elapsed Time (minutes)", ylab="% Utilization")

grid(col="gray")
invisible(dev.off())
__EOF__
