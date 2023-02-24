#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2014      Mark Wong
#               2014      2ndQuadrant, Ltd.
#

INPUTFILE=$1
OUTPUTDIR=$2

if [ $# -ne 2 ]; then
	echo "Create a plot the rate of transactions."
	echo "usage: `basename $0` <sar-blockdev.csv> <output directory>"
	echo
	echo "    <sar-blockdev.csv> - full path to the sar-blockdev.csv file"
	echo "    <output directory> - location to write output files"
	echo
	echo "Will attempt to create <output directory> if it does not exist."
	exit 1
fi

R --slave --no-save << __EOF__
df <- read.csv("$INPUTFILE", sep = ";", header=T)
starttime = df[1,]\$timestamp
df\$timestamp <- ceiling((df\$timestamp - starttime) / 60)
devices <- sort(unique(df\$DEV))
count <- length(devices)
color <- rainbow(count)
pch <- seq.int(1, count)

# Convert kilobytes to megabytes, without renaming the column...
df\$rkB.s <- df\$rkB.s / 1024
df\$wkB.s <- df\$wkB.s / 1024

# Plot all device utilization on a single chart.

df.all <- subset(df, df\$DEV == devices[1])
bitmap("${OUTPUTDIR}/sar-blockdev-util.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df.all\$timestamp, df.all\$X.util,
     ylim=c(0, 100), type = "b", col = color[1],
     main="Block Device Utilization",
     xlab="Elapsed Time (minutes)", ylab="% Utilization")

for (i in 2:count) {
  df.all <- subset(df, df\$DEV == devices[i])
  points(df.all\$timestamp, df.all\$X.util, type = "b", pch = pch[i],
         col=color[i])
}

legend('topright', sapply(devices, as.character), pch=pch, col=color)

grid(col="gray")
invisible(dev.off())

# Plot all device tps on a single chart.

df.all <- subset(df, df\$DEV == devices[1])
bitmap("${OUTPUTDIR}/sar-blockdev-tps.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df.all\$timestamp, df.all\$tps,
     ylim=c(0, max(df\$tps)), type = "b", col = color[1],
     main="Transfers per Second",
     xlab="Elapsed Time (minutes)", ylab="")

for (i in 2:count) {
  df.all <- subset(df, df\$DEV == devices[i])
  points(df.all\$timestamp, df.all\$tps, type = "b", pch = pch[i],
         col=color[i])
}

legend('topright', sapply(devices, as.character), pch=pch, col=color)

grid(col="gray")
invisible(dev.off())

df.all <- subset(df, df\$DEV == devices[1])
bitmap("${OUTPUTDIR}/sar-blockdev-await.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df.all\$timestamp, df.all\$await,
     ylim=c(0, max(df\$await)), type = "b", col = color[1],
     main="Average Wait",
     xlab="Elapsed Time (minutes)", ylab="Milliseconds")

for (i in 2:count) {
  df.all <- subset(df, df\$DEV == devices[i])
  points(df.all\$timestamp, df.all\$await, type = "b", pch = pch[i],
         col=color[i])
}

legend('topright', sapply(devices, as.character), pch=pch, col=color)

grid(col="gray")
invisible(dev.off())

df.all <- subset(df, df\$DEV == devices[1])
bitmap("${OUTPUTDIR}/sar-blockdev-avgqu.sz.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df.all\$timestamp, df.all\$aqu.sz,
     ylim=c(0, max(df\$aqu.sz)), type = "b", col = color[1],
     main="Average Queue Length",
     xlab="Elapsed Time (minutes)", ylab="Length")

for (i in 2:count) {
  df.all <- subset(df, df\$DEV == devices[i])
  points(df.all\$timestamp, df.all\$aqu.sz, type = "b", pch = pch[i],
         col=color[i])
}

legend('topright', sapply(devices, as.character), pch=pch, col=color)

grid(col="gray")
invisible(dev.off())

df.all <- subset(df, df\$DEV == devices[1])
bitmap("${OUTPUTDIR}/sar-blockdev-avgrq.sz.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df.all\$timestamp, df.all\$areq.sz,
     ylim=c(0, max(df\$areq.sz)), type = "b", col = color[1],
     main="Average Request Size",
     xlab="Elapsed Time (minutes)", ylab="Sectors")

for (i in 2:count) {
  df.all <- subset(df, df\$DEV == devices[i])
  points(df.all\$timestamp, df.all\$areq.sz, type = "b", pch = pch[i],
         col=color[i])
}

legend('topright', sapply(devices, as.character), pch=pch, col=color)

grid(col="gray")
invisible(dev.off())

# Plot megabytes read/write per device

label <- c('Reads', 'Writes')
color <- rainbow(2)
pch <- c(1, 2)
for (dev in devices) {
  df.all <- subset(df, df\$DEV == dev)
  bitmap(paste("${OUTPUTDIR}/sar-blockdev-", dev, "-rw.png", sep = ""),
         type="png16m", units="px", width=1280, height=800, res=150, taa=4,
         gaa=4)
  plot(df.all\$timestamp, df.all\$rkB.s,
       ylim=c(0, max(max(df.all\$rkB.s), max(df.all\$wkB.s))),
       type = "b", col = color[1],
       main=paste("Block Device ", dev, " Read/Write", sep = ""),
       xlab="Elapsed Time (minutes)", ylab="MegaBytes/s")
  points(df.all\$timestamp, df.all\$wkB.s, type = "b", pch = pch[2],
         col=color[2])

  legend('topright', label, pch=pch, col=color)

  grid(col="gray")
dev.off()

}
__EOF__
