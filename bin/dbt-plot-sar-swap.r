#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright The DBT Tools Authors
#

INPUTFILE=$1
OUTPUTDIR=$2

if [ $# -ne 2 ]; then
	echo "Create a plot of swap statistics."
	echo "usage: `basename $0` <sar-swap.csv> <output directory>"
	echo
	echo "    <sar-swap.csv> - full path to the sar-net.csv file"
	echo "    <output directory> - location to write output files"
	echo
	echo "Will attempt to create <output directory> if it does not exist."
	exit 1
fi

R --slave --no-save << __EOF__
df <- read.csv("$INPUTFILE", sep=";", header=T)
starttime = df[1,]\$timestamp
df\$timestamp <- ceiling((df\$timestamp - starttime) / 60)

# Plot pages swapped in/out.

label <- c('pswpin/s', 'pswpout/s')
color <- rainbow(2)
pch <- c(1, 2)
bitmap(paste("$OUTPUTDIR/sar-swap.png", sep=""),
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df\$timestamp, df\$pswpin.s,
     ylim=c(0, max(max(df\$pswpin.s), max(df\$pswpout.s))),
     type = "b", col = color[1],
     main=paste("Swap Activity", sep=""),
     xlab="Elapsed Time (minutes)", ylab="Pages/s")
points(df\$timestamp, df\$pswpout.s, type = "b", pch = pch[2],
       col=color[2])

legend('topright', label, pch=pch, col=color)

grid(col="gray")
invisible(dev.off())
__EOF__
