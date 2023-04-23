#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright The DBT Tools Authors
#

SIZE="1600,1000"

if [ $# -lt 5 ]; then
	echo "$(basename "${0}") is the DBT transaction distribution plotter"
	echo ""
	echo "Usage:"
	echo "  $(basename "${0}") <txn name> <txn id> <output directory> <color index> <log0> [log1 [...]]"
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
# TODO: Handle color.
shift

mkdir -p "${OUTPUTDIR}"
if [ ! -d "${OUTPUTDIR}" ]; then
	echo "Failed to create directory ${OUTPUTDIR}"
	exit 1
fi

DATAFILE=$(mktemp)

for FILENAME in "${@}"; do
	awk -F ',' -v TXN="${TXN_TAG}" '$2 == TXN {print $1, $4}' "${FILENAME}" \
			>> "${DATAFILE}"
done

gnuplot << EOF
datafile = "${DATAFILE}"
set xdata time
set timefmt "%s"
set terminal pngcairo size $SIZE
set xlabel "Time"
set xtics rotate
set xtics format "%R"
set grid
set title "${TXN_NAME} Transaction Response Time Distribution" noenhanced
set output "${OUTPUTDIR}/t${TXN_TAG}-distribution.png"
set ylabel "Response Time (seconds)"
set key off
plot datafile using 1:2 notitle with points
EOF

rm -f "${DATAFILE}"
