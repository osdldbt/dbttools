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
	echo "usage: `basename $0` <sar-cpu.csv> <output directory>"
	echo
	echo "    <sar-cpu.csv> - full path to the sar-cpu.csv file"
	echo "    <output directory> - location to write output files"
	echo
	echo "Will attempt to create <output directory> if it does not exist."
	exit 1
fi

R --slave --no-save << __EOF__
df <- read.csv("$INPUTFILE", sep = ";", header=T)
starttime = df[1,]\$timestamp
df\$timestamp <- ceiling((df\$timestamp - starttime) / 60)

# Plot average of all processors

df.all <- subset(df, df\$CPU == -1)

type <- c("X.user", "X.system", "X.iowait", "X.idle")
label <- c("User", "System", "Iowait", "Idle")
color <- rainbow(4)
pch <- seq.int(1, 4)

bitmap("${OUTPUTDIR}/sar-cpu.png",
       type="png16m", units="px", width=1280, height=800, res=150, taa=4,
       gaa=4)
plot(df.all\$timestamp, df.all\$X.user,
     ylim=c(0, 100), type = "b", col = color[1],
     main="Aggregated Processor Utilization",
     xlab="Elapsed Time (minutes)", ylab="% Utilization")

for (i in 2:4) {
  points(df.all\$timestamp, df.all[[type[i]]], type = "b", pch = pch[i],
         col=color[i])
}

legend('topright', label, pch=pch, col=color)

grid(col="gray")
invisible(dev.off())

# Plot each processor individually

lastcpu <- max(df\$CPU)

for (i in 0:lastcpu) {
  df.all <- subset(df, df\$CPU == i)

  type <- c("X.user", "X.system", "X.iowait", "X.idle")
  label <- c("User", "System", "Iowait", "Idle")
  color <- rainbow(4)
  pch <- seq.int(1, 4)

  bitmap(paste("${OUTPUTDIR}/sar-cpu", i, ".png", sep = ""),
         type="png16m", units="px", width=1280, height=800, res=150, taa=4,
         gaa=4)
  plot(df.all\$timestamp, df.all\$X.user,
       ylim=c(0, 100), type = "b", col = color[1],
	   main=paste("CPU ", i, " Processor Utilization"),
       xlab="Elapsed Time (minutes)", ylab="% Utilization")

  for (i in 2:4) {
    points(df.all\$timestamp, df.all[[type[i]]], type = "b", pch = pch[i],
           col=color[i])
  }

  legend('topright', label, pch=pch, col=color)

  grid(col="gray")
  invisible(dev.off())
}

# Plot % busy of all processors on the same chart.
label <- sapply(seq.int(1, lastcpu + 1), as.character)
color <- rainbow(lastcpu + 1)
pch <- seq.int(1, lastcpu + 1)

df\$X.idle <- 100 - df\$X.idle
for (i in 0:lastcpu) {
  df.all <- subset(df, df\$CPU == 0)

  bitmap("${OUTPUTDIR}/sar-cpu-all.png",
         type="png16m", units="px", width=1280, height=800, res=150, taa=4,
         gaa=4)
  plot(df.all\$timestamp, df.all\$X.idle,
       ylim=c(0, 100), type = "b", col = color[1],
       main="Processor Utilization",
       xlab="Elapsed Time (minutes)", ylab="% Busy")

  for (i in 1:lastcpu) {
    df.all <- subset(df, df\$CPU == i)
    points(df.all\$timestamp, df.all\$X.idle, type = "b", pch = pch[i + 1],
           col=color[i + 1])
  }

  legend('topright', label, pch=pch, col=color)

  grid(col="gray")
  invisible(dev.off())
}
__EOF__
