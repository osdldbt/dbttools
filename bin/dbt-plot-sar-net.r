#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2015      Mark Wong
#               2015      2ndQuadrant, Ltd.
#

INPUTFILE=$1
OUTPUTDIR=$2

if [ $# -ne 2 ]; then
	echo "Create a plot of network statistics."
	echo "usage: `basename $0` <sar-net.csv> <output directory>"
	echo
	echo "    <sar-net.csv> - full path to the sar-net.csv file"
	echo "    <output directory> - location to write output files"
	echo
	echo "Will attempt to create <output directory> if it does not exist."
	exit 1
fi

R --slave --no-save << __EOF__
df <- read.csv("$INPUTFILE", sep = ";", header=T)
starttime = df[1,]\$timestamp
df\$timestamp <- ceiling((df\$timestamp - starttime) / 60)
devices <- sort(unique(df\$IFACE))
count <- length(devices)
color <- rainbow(count)
pch <- seq.int(1, count)

# Plot send/receive throughput per device

label <- c('rxkB/s', 'txkB/s')
color <- rainbow(2)
pch <- c(1, 2)
for (dev in devices) {
  df.all <- subset(df, df\$IFACE == dev)
  bitmap(paste("${OUTPUTDIR}/sar-net-", dev, "-x.png", sep = ""),
         type="png16m", units="px", width=1280, height=800, res=150, taa=4,
         gaa=4)
  plot(df.all\$timestamp, df.all\$rxpck.s,
       ylim=c(0, max(max(df.all\$rxpck.s), max(df.all\$txpck.s))),
       type = "b", col = color[1],
       main=paste("Network Device ", dev, " Receive/Transmit", sep = ""),
       xlab="Elapsed Time (minutes)", ylab="KiloBytes/s")
  points(df.all\$timestamp, df.all\$txpck.s, type = "b", pch = pch[2],
         col=color[2])

  legend('topright', label, pch=pch, col=color)

  grid(col="gray")
  invisible(dev.off())
}

# Plot network device utilization.

count <- length(devices)
color <- rainbow(count)
pch <- seq.int(1, count)

df.all <- subset(df, df\$IFACE == devices[1])
bitmap(paste("${OUTPUTDIR}/sar-net-util.png", sep = ""),
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df.all\$timestamp, df.all\$X.ifutil,
     ylim=c(1, 100),
     type = "b", col = color[1],
     main=paste("Network Device % Utilization", sep = ""),
     xlab="Elapsed Time (minutes)", ylab="% Utilization")
for (i in 2:count) {
  df.all <- subset(df, df\$IFACE == devices[i])
  points(df.all\$timestamp, df.all\$X.ifutil, type = "b", pch = pch[i],
         col=color[i])
}
legend('topright', devices, pch=pch, col=color)

grid(col="gray")
invisible(dev.off())
__EOF__
